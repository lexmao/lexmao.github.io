#####阅读nginx代码(1)

-- Stone <stone@bzline.cn>
***



掌握以下几点:

* master-worker的并发模型
* 信号处理方法
* master-worker通信管理方法
* worker accept lock方法
* 状态机
* IO多路复用
* 红黑树处理超时
* worker进程之间的balance控制

***


#####master-worker的并发模型


                           master process
                                  |
                                  |
           ___________________________
           |          |            |               |
           worker1    worker2   worker3 ...... worke(n)
           

           master 主进程,负责创建Listen socket
           master 监控worker进程状态(exit...??)
           master 接收外部的指令(主要是信号),然后负责和worker进行通信,统一管理worker进程,

           worker进程由master进程创建后,开始独立进行工作.
           worker进程accept新的连接,然后通过IO多路复用处理IO网络请求.
           worker中通过状态机来处理具体的事务.

master怎样管理worker ?
      
   
       一个全局的ngx_processes变量,每一个worker对应一个数组中的元素 ngx_processes[n]
       这里要注意的是,这样每个进程(包括1个master和n 个worker进程)都有一个ngx_processes的复制版本.那么,怎么确保这个变量的每个副本内容的一致性呢?

       通常的办法,是通过mmap的方式把ngx_process映射为共享的内存. 但是在ngx中,是通过master-worker通信的方式来通知该变量的变化.
        
   ``` 
   ngx_process_t    ngx_processes[NGX_MAX_PROCESSES]; 

    /* 数据结构*/
    typedef struct {
    	ngx_pid_t           pid;  /*worker 的pid*/
    	int                 status;
    	ngx_socket_t        channel[2];  /*master-worker通信handle (fd)*/

    	ngx_spawn_proc_pt   proc;   /*worker进行任务的函数指针*/
    	void               *data;
    	char               *name;

    	unsigned            respawn:1;
    	unsigned            just_respawn:1;
    	unsigned            detached:1;
    	unsigned            exiting:1;
    	unsigned            exited:1;
	} ngx_process_t;
	
```



下面我们看看worker进程启动的整个逻辑


```
main()
{
     ......初始化代码....

	if (ngx_process == NGX_PROCESS_MASTER) {
        ngx_master_process_cycle(cycle);

    } else {
        ngx_single_process_cycle(cycle);
    }

}
```

跟进到 ngx_master_process_cycle
       
 ```
     
ngx_master_process_cycle (..)
{
      ....
      ngx_start_worker_processes(cycle, ccf->worker_processes,
                               NGX_PROCESS_RESPAWN);

           /**master的主Loop
            *在nginx服务期间,master进程就生活在以下循环:)
            */
       for ( ;; ) {

           /* 定时器*/
           if (delay) {}
           
           /* 启动信号处理机制*/ 
           sigsuspend(&set);  
                         
           /*根据各种标志进行逻辑处理*/
           if (ngx_reap) {}
           if (!live && (ngx_terminate || ngx_quit)) {}
           if (ngx_terminate) {}
           if (ngx_reconfigure){}
             ......                      
                      
        }//for main loop
}
```

 跟进到 ngx_start_worker_processes,看看worker进程到底是怎么产生的
 
 ```     
 
 ngx_start_worker_processes(..)
 {
               ...
       for (i = 0; i < n; i++) {  /* n=ccf->worker_processes*/
                        .....
             /*下面的函数产生一个新的worker进程,并返回到master进程*/
           ngx_spawn_process(cycle, ngx_worker_process_cycle, NULL, "worker 					process", type);

           ch.pid = ngx_processes[ngx_process_slot].pid;
           ch.slot = ngx_process_slot;
           ch.fd = ngx_processes[ngx_process_slot].channel[0];

           /** 
           *下面的代码就是通过channel进程间通信,把ngx_processes的
           *数据同步到所有存在的worker进程
           */
           for (s = 0; s < ngx_last_process; s++) {
           		ngx_write_channel(ngx_processes[s].channel[0],  &ch,sizeof(ngx_channel_t),  cycle->log);
            } // end for
       }//end main for
}
```

  
到底worker进程是怎么产生的??我要看到fork ...跟进到 ngx_spawn_process
    
```
ngx_spawn_process()
{
          ....
       /*获得ngx_processes可用的索引s*/
       for (s = 0; s < ngx_last_process; s++) {
            if (ngx_processes[s].pid == -1) {
                break;
            }
       }

       /*设置channel通信的相关代码*/
      if (socketpair(AF_UNIX, SOCK_STREAM, 0, ngx_processes[s].channel) == -1)
             .....
  
       /**终于看到了期待的fork */
      pid=fork();
      switch (pid) {

     	case -1:
        	return NGX_INVALID_PID;

    	case 0:
        	ngx_pid = ngx_getpid();
        	proc(cycle, data);   //worker 进程处理任务的proc函数
        	break;

    	default:
        	break;
       }//switch end


            /**
             * fork后子进程由于进入proc过程,所以进入以下逻辑代码的是master进程
             *产生worker后设置master 进程的ngx_processes[s]
             */

       ngx_processes[s].pid = pid;
       ngx_processes[s].exited = 0;
             .....

       if (s == ngx_last_process) {
            ngx_last_process++;
       }

}//main
```


 最后,我们来看看worker进程进入proc处理过程的具体逻辑
 
 ```   
ngx_worker_process_cycle(ngx_cycle_t *cycle, void *data)
{
                  .....
                  
        for ( ;; ) {


              /*io event 驱动,进行主要逻辑处理
               * 也是我们后面要分析的主要内容
               */
               ngx_process_events_and_timers(cycle);

               /*根据各种标志进行逻辑处理*
                if (ngx_exiting) {}
                if (ngx_terminate) {}
                if (ngx_quit) {} 
                     .....
                       

         }/*main for*/
}
```


#####信号处理方式

Nginx 处理信号的流程和方式:

          当产生信号后,master和worker都可以接收到,但是处理方式区别开来.
          处理过程主要是设置各种标志.然后后续根据各种标志进行具体的逻辑处理.


信号的一些知识回顾

    进程中会发生一些软中断事件.比如键盘输入中断键、内存非法应用、管道终止、alarm 等等行为都可
    能发生中断事件.
    
    当这些事件发生后怎么办? 有些中断不处理可能不影响进程的工作,但是有些不处理可能会导致进程异常.
    
    事实上,操作系统把是否要处理的选择权利交给程序员: 在这些事件发送的时候,操作系统会发送一个信号
    给进程,针对这些事件具体怎么处理让程序员来控制(通过信号处理函数),当然,有些事件操作系统强制进
    行处理,如9号信号. (kill -9 )，这个处理过程是典型的异步操作。

    这样看来，一个进程总会发生些意外（尽管有些意外是程序员设计好，希望发生的），所以我们还是针对
    各个信号事件进行统一处理比较好，而不是任由它去。我习惯程序的行为是在我的控制之中。


    编号为0 的信号的意义及用途:
    这是一个空信号，但是调用kill(pid,0)的时候，kill仍然正常检查返回，这通常用来检查一个进程是
    否存在。
    kill(0,signo) 表示向同一进程组发送signo信号。
    
    
    信号在进程中是随机出现。
    当中断发生时，被中断的是系统调用而不是我们的函数。
    当程序启动时（exec)，exec函数会将原来设置为捕捉的信号都更改为默认动作，因为当exec执行一个
    新的程序后，新的程序不能捕获到信号了，因为信号处理函数的地址在新进程可能已经毫无意义。
    
    当fork一个子进程后，子进程将会继承父进程的信号处理方式。因为信号处理函数的地址，在子进程中是
    有意义的（fork后，子进程复制了父进程的存储映像）。
    
    信号处理函数中，主要不可重入函数问题。
    在执行慢速的系统调用的时候，进程很可能阻塞几个小时或者数天，如果进程在执行一个低速系统调用期
    间捕捉到一个信号的时候，那么该系统调用就被中断不再继续执行。
    因为一个信号发生了，这就意味着发生了某种事情，所以这是唤醒被阻塞的进程的好机会。
    所以，我们经常这样来处理问题：
    
    again:
    if(read(fd,buffer,size)<0){
         if(errno==EINTR) goto again;/*just an interrupted system call*
    }

    为了帮助应用进程不必处理被中断的系统调用，linux系统引入了某些被中断系统调用的自动重启函数，
    包括：Ioctl，read，readv，write，writev，wait和waitpid。前5个只对低速设备调用才有效，
    而后两个只对捕捉到进程退出信号时才有效。 
    所以在Linux系统下，由于被中断的read可以自动重启，所以不必来处理中断的问题。（但是为了系统的
    可移植性，我们通常还是按上面的方式处理）。
    
    用下面的代码来证实系统 read 确实在被中断后重新启动：
    
    
    
```  

void sig_handle(int signo)
{
    fprintf(stderr,"have sig handler...here\n");

    return;
}


int main()
{
        int n;
        char buf[128]={0};

        signal(SIGUSR1,sig_handle);

        while(1){
                n=read(0,buf,sizeof(buf)-1);
                printf("n=%d\n",n);

                if(n<0){
                        perror("read..\n");
                }
        }


}



[root@Office-Dev-VS-101-21 ~]# killall -10 test_sig
[root@Office-Dev-VS-101-21 LAB]# ./test_sig
hi,sig handler...here
sss
n=4
have sig handler...here
have sig handler...here

```

    以上程序证实在Linux系统下，系统调用read被中断后确实重新自动启动（未返回n值,perror).

    现在为止,我们已经知道信号问题是我们在进程中必须要处理的,特别是服务进程.那么通常
    在服务器进程中我们要处理那些信号,怎么处理呢?


我们来看看nginx中是怎么处理以上问题的.

任何一个信号,我们认为它具备以下三个要素:信号编号,信号名称,信号处理函数.
nginx用以下结构来定义.

```
typedef struct {
     int     signo;
     char   *signame;
     void  (*handler)(int signo);
} ngx_signal_t;
```

要处理的信号,放在一个数组中:

```
ngx_signal_t  signals[] = {
    { ngx_signal_value(NGX_RECONFIGURE_SIGNAL),  /* SIGHUP */
      "SIG" ngx_value(NGX_RECONFIGURE_SIGNAL),
      ngx_signal_handler },

    { ngx_signal_value(NGX_REOPEN_SIGNAL),   /* SIGINFO*/
      "SIG" ngx_value(NGX_REOPEN_SIGNAL),
      ngx_signal_handler },

    { ngx_signal_value(NGX_NOACCEPT_SIGNAL),  /*WINCH*/
      "SIG" ngx_value(NGX_NOACCEPT_SIGNAL),
      ngx_signal_handler },

    { ngx_signal_value(NGX_TERMINATE_SIGNAL), /*TERM*/
      "SIG" ngx_value(NGX_TERMINATE_SIGNAL),
      ngx_signal_handler },

    { ngx_signal_value(NGX_SHUTDOWN_SIGNAL), /*QUIT*/
      "SIG" ngx_value(NGX_SHUTDOWN_SIGNAL),
      ngx_signal_handler },

    { ngx_signal_value(NGX_CHANGEBIN_SIGNAL),  /*USER2*/
      "SIG" ngx_value(NGX_CHANGEBIN_SIGNAL),
      ngx_signal_handler },

    { SIGALRM, "SIGALRM", ngx_signal_handler },

    { SIGINT, "SIGINT", ngx_signal_handler },

    { SIGIO, "SIGIO", ngx_signal_handler },

    { SIGCHLD, "SIGCHLD", ngx_signal_handler },

    { SIGPIPE, "SIGPIPE, SIG_IGN", SIG_IGN },

    { 0, NULL, NULL }
};
```

处理函数:

```
void ngx_signal_handler(int signo)
{
    char            *action;
    ngx_int_t        ignore;
    ngx_err_t        err;
    ngx_signal_t    *sig;

    ignore = 0;

    err = ngx_errno;

    for (sig = signals; sig->signo != 0; sig++) {
        if (sig->signo == signo) {
            break;
        }
    }

    ngx_time_update(0, 0);

    action = "";

    switch (ngx_process) {

    case NGX_PROCESS_MASTER:
    case NGX_PROCESS_SINGLE:
        switch (signo) {

        case ngx_signal_value(NGX_SHUTDOWN_SIGNAL):
            ngx_quit = 1;
            action = ", shutting down";
            break;

        case ngx_signal_value(NGX_TERMINATE_SIGNAL):
        case SIGINT:
            ngx_terminate = 1;
            action = ", exiting";
            break;

        case ngx_signal_value(NGX_NOACCEPT_SIGNAL):
            ngx_noaccept = 1;
            action = ", stop accepting connections";
            break;

        case ngx_signal_value(NGX_RECONFIGURE_SIGNAL):
            ngx_reconfigure = 1;
            action = ", reconfiguring";
            break;

        case ngx_signal_value(NGX_REOPEN_SIGNAL):
            ngx_reopen = 1;
            action = ", reopening logs";
            break;

        case ngx_signal_value(NGX_CHANGEBIN_SIGNAL):
            if (getppid() > 1 || ngx_new_binary > 0) {

                /*
                 * Ignore the signal in the new binary if its parent is
                 * not the init process, i.e. the old binary's process
                 * is still running.  Or ignore the signal in the old binary's
                 * process if the new binary's process is already running.
                 */

                action = ", ignoring";
                ignore = 1;
                break;
            }

            ngx_change_binary = 1;
            action = ", changing binary";
            break;

        case SIGALRM:
            break;

        case SIGIO:
            ngx_sigio = 1;
            break;

        case SIGCHLD:
            ngx_reap = 1;
            break;
        }

        break;

        case ngx_signal_value(NGX_SHUTDOWN_SIGNAL):
            ngx_quit = 1;
            action = ", shutting down";
            break;

        case ngx_signal_value(NGX_TERMINATE_SIGNAL):
        case SIGINT:
            ngx_terminate = 1;
            action = ", exiting";
            break;

        case ngx_signal_value(NGX_NOACCEPT_SIGNAL):
            ngx_noaccept = 1;
            action = ", stop accepting connections";
            break;

        case ngx_signal_value(NGX_RECONFIGURE_SIGNAL):
            ngx_reconfigure = 1;
            action = ", reconfiguring";
            break;

        case ngx_signal_value(NGX_REOPEN_SIGNAL):
            ngx_reopen = 1;
            action = ", reopening logs";
            break;

        case ngx_signal_value(NGX_CHANGEBIN_SIGNAL):
            if (getppid() > 1 || ngx_new_binary > 0) {

                /*
                 * Ignore the signal in the new binary if its parent is
                 * not the init process, i.e. the old binary's process
                 * is still running.  Or ignore the signal in the old binary's
                 * process if the new binary's process is already running.
                 */

                action = ", ignoring";
                ignore = 1;
                break;
            }

            ngx_change_binary = 1;
            action = ", changing binary";
            break;

        case SIGALRM:
            break;

        case SIGIO:
            ngx_sigio = 1;
            break;

        case SIGCHLD:
            ngx_reap = 1;
            break;
        }

        break;

    case NGX_PROCESS_WORKER:
        switch (signo) {

        case ngx_signal_value(NGX_NOACCEPT_SIGNAL):
            ngx_debug_quit = 1;
        case ngx_signal_value(NGX_SHUTDOWN_SIGNAL):
            ngx_quit = 1;
            action = ", shutting down";
            break;

        case ngx_signal_value(NGX_TERMINATE_SIGNAL):
        case SIGINT:
            ngx_terminate = 1;
            action = ", exiting";
            break;

        case ngx_signal_value(NGX_REOPEN_SIGNAL):
            ngx_reopen = 1;
            action = ", reopening logs";
            break;

        case ngx_signal_value(NGX_RECONFIGURE_SIGNAL):
        case ngx_signal_value(NGX_CHANGEBIN_SIGNAL):
        case SIGIO:
            action = ", ignoring";
            break;
        }

        break;
        switch (signo) {

        case ngx_signal_value(NGX_NOACCEPT_SIGNAL):
            ngx_debug_quit = 1;
        case ngx_signal_value(NGX_SHUTDOWN_SIGNAL):
            ngx_quit = 1;
            action = ", shutting down";
            break;

        case ngx_signal_value(NGX_TERMINATE_SIGNAL):
        case SIGINT:
            ngx_terminate = 1;
            action = ", exiting";
            break;

        case ngx_signal_value(NGX_REOPEN_SIGNAL):
            ngx_reopen = 1;
            action = ", reopening logs";
            break;

        case ngx_signal_value(NGX_RECONFIGURE_SIGNAL):
        case ngx_signal_value(NGX_CHANGEBIN_SIGNAL):
        case SIGIO:
            action = ", ignoring";
            break;
        }

        break;
    }

    ngx_log_error(NGX_LOG_NOTICE, ngx_cycle->log, 0,
                  "signal %d (%s) received%s", signo, sig->signame, action);

    if (ignore) {
        ngx_log_error(NGX_LOG_CRIT, ngx_cycle->log, 0,
                      "the changing binary signal is ignored: "
                      "you should shutdown or terminate "
                      "before either old or new binary's process");
    }

    if (signo == SIGCHLD) {
        ngx_process_get_status();
    }

    ngx_set_errno(err);

}
```

    信号处理函数中，处理的变量定义为：sig_atomic_t类型。
    sig_atomic_t，当把变量声明为该类型会保证该变量在使用或赋值时， 无论是在32位还是64位的机器
    上都能保证操作是原子的，它会根据机器的类型自动适应。


信号编号,信号名称,信号处理函数我们确定后,那么在服务进程初始化期间,我们也要初始化信号:

```
ngx_int_t ngx_init_signals(ngx_log_t *log)
{
    ngx_signal_t      *sig;
    struct sigaction   sa;

    for (sig = signals; sig->signo != 0; sig++) {
        ngx_memzero(&sa, sizeof(struct sigaction));/*memset()*/
        sa.sa_handler = sig->handler;
        sigemptyset(&sa.sa_mask);
        if (sigaction(sig->signo, &sa, NULL) == -1) {
            ngx_log_error(NGX_LOG_EMERG, log, ngx_errno,
                          "sigaction(%s) failed", sig->signame);
            return NGX_ERROR;
        }
    }

    return NGX_OK;
}
```


由以上红色部分可以看到,这是父进程都需要处理的信号.下面我们具体看看这些信号.
绿色部分是子进程要处理的信号.

SIGHUP用来处理重新读配置文件的用途. 为什么用SIGHUP,怎么实现重新读配置文件功能?  
从上面的代码看到,SIGUP在子进程中是不管的（ ignoring,即捕获该信号但是什么都不做）,而在父进程中是置ngx_reconfigure = 1.用来实现配置文件重新load.
       
Master 进程接收到SIGHUP后，设置ngx_reconfigure=1。然后在master的main loop过程中
（ngx_master_process_cycle）定时检查ngx_reconfigure标志是否为1，
 
 ```
if (ngx_reconfigure) {
   ngx_reconfigure = 0;

          
   cycle = ngx_init_cycle(cycle);  //初始化全局变量
          
   ngx_cycle = cycle;
   
   //重新读取配置文件参数
   ccf = (ngx_core_conf_t *) ngx_get_conf(cycle->conf_ctx,ngx_core_module);
    
   // 启动新的work进程
   //设置为NGX_PROCESS_JUST_RESPAWN标志,表示在 下面 ngx_signal_worker_processes 
   //中kill worker的时候,遇到该标志就不kill了
   
   ngx_start_worker_processes(cycle, ccf->worker_processes,    
                                       NGX_PROCESS_JUST_RESPAWN);  
                                       
                                                    
   //向其他worker进程发送QUIT信号,kill 老的worker进程
   ngx_signal_worker_processes(cycle, ngx_signal_value(NGX_SHUTDOWN_SIGNAL));  
   
}
```



     ctl+c产生SIGINT，而ctl+\产生SIGQUIT, SIGTERM 程序结束(terminate)信号, 与SIGKILL不
     同的是该信号可以被阻塞和 处理. 通常用来要求程序自己正常退出. shell命令kill缺省产生这个信
     号. 
     SIGQUIT 用来实现shutdown. 父子进程中都捕获,并分别设置ngx_quit变量
     SIGTERM 信号,父子进程设置 ngx_terminate变量.


在父进程开始工作的时候,将会处理一些初始化的工作,这时候我们要尽量避免被信号中断,
这些代码我们可以叫做临界代码. 看看下面的处理:

```

int main()
{
        int n=0;
        int child_num=4;
        sigset_t           set;


    /**
     *设置信号处理:包括需要处理那些信号及处理方法
     */
          n=kiss_signal_init(signals);

      /**
       *然后对这些设置的信号进行堵塞，这样做的原因有：
        *1 ，这样下面创建的子进程就不会接收外部发送的信号
        *2 ，在处理以下临界代码的时候不会被信号中断
        */

        sigemptyset(&set);
        sigaddset(&set, SIGCHLD);
        sigaddset(&set, SIGHUP);
        sigprocmask(SIG_BLOCK, &set, NULL);

        sigemptyset(&set);

        kiss_process=MASTER_PROCESS;
        
        /*创建出指定数量的子进程（worker）,并设置kiss_process=WORKER_PROCESS;*/
        while(kiss_process==MASTER_PROCESS && child_num>0){

                if(fork()==0){//child
                        kiss_process=WORKER_PROCESS;
                }else child_num--;
        }


		/*做worker该做得具体逻辑*/
        if(kiss_process==WORKER_PROCESS){
                printf("this is child(%d)\n",getpid());
                pause();
                exit(120);

        }

        if(kiss_process==MASTER_PROCESS){
                printf("this is master (%d)\n",getpid());
                while(1){
                         /**
                         *父进程完成上面的任务后，恢复信号处理。
                         */
                         sigsuspend(&set);
                }
                return (0);
        }

}
```

所以，当一个信号发送给server后，主（父）进程接收该信号，并通过处理函数进行处理。
然后通过把该指令通过管道或者其他进程间的通信发送下发给子进程。




到目前为止，我们应该了解到写一个服务器程序的模型应该如下：

```
int main()
{
        int n=0;
        int child_num=4;
        sigset_t           set;


    /**
     *设置信号处理:包括需要处理那些信号及处理方法
     */
          n=kiss_signal_init(signals);

      /**
       *然后对这些设置的信号进行堵塞，这样做的原因有：
        *1 ，这样下面创建的子进程就不会接收外部发送的信号
        *2 ，在处理以下临界代码的时候不会被信号中断
        */

        sigemptyset(&set);
        sigaddset(&set, SIGCHLD);
        sigaddset(&set, SIGHUP);
        sigprocmask(SIG_BLOCK, &set, NULL);

        sigemptyset(&set);


        kiss_process=MASTER_PROCESS;

       /**
        *启动工作进程（子进程）
        while(kiss_process==MASTER_PROCESS && child_num>0){

                if(fork()==0){//child
                        kiss_process=WORKER_PROCESS;
                        
                }else child_num--;
        }

          /**下面是子进程部分代码*/

        if(kiss_process==WORKER_PROCESS){
               while(true){
                  /*do work thing ...*/

            
                /**不堵塞任何信号...之前被父进程设置为堵塞,所以这里放开*/
                  sigemptyset(&set);
                   if (sigprocmask(SIG_SETMASK, &set, NULL) == -1) {
                           ...
                   }
                     ......
               }
                exit(0);
         }


          /**下面是父进程（主进程）代码*/
        if(kiss_process==MASTER_PROCESS){
                printf("this is master (%d)\n",getpid());
                while(true){
                           /**
                           *这里可以设置超时代码，用来定时检查相关任务
                           */

                          /**
                         *父进程完成上面的任务后，恢复信号处理。
                         *堵塞在下面的sigsuspend函数，除非接收到set设置的信号
                         */                                   
                         sigsuspend(&set);

                         /*接收到外部信号后，负责通知子进程*/
                          mastr_child_channel();
               

                      
                }
                return (0);
        }

}

```


     sigsuspend: 1,解除block的信号; 2,堵塞(类似pause()),直到有信号到来激活. 
     他的特别之处在于实现以上2个操作,它保证了原子性.

     如果用
             sigprocmask(SIG_BLOCK, &set, NULL);
             pause()

     来代替该函数,可能导致信号在 sigprocmask(SIG_BLOCK, &set, NULL)之后pause之前到来,这时
     候将永远堵塞在pause()上.



信号处理总结
             
    针对父子进程,区别对待信号的处理方式.
    信号的三要素: 信号量、信号名称、信号处理函数 及信号的初始化方式
    信号处理函数要避免重入等因素，所以最好好的方式是只设置标志。主循环中根据设置的标志做具体的逻辑处理.
    服务在初始化的过程中，对临界区代码的处理（防止这片代码被信号中断）
    
    

最后，还了解了一种网络服务器程序架构的主要构建方式。

[demo代码](https://github.com/lexmao/blog_source/blob/master/clib/server.c)




   




