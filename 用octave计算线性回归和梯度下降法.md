####用Octave求解最下二乘法的两种方法
2013年9月29日

####问题：有一组数据（200条）。如果有新的输入x,请预估出其对应y值。

  数据如下：
  
    x                  y
   ![Mou icon](http://lexmao.com/images/Liner-0.png)
  
  
  
   假设的回归方程：
 
      
   ![Mou icon](http://lexmao.com/images/Liner-1.png)
  
   假设x0=1,则可以表示为：
  
  
   ![Mou icon](http://lexmao.com/images/Liner-2.png)
  
   为了求得⍬，采用损失函数：
  
   ![Mou icon](http://lexmao.com/images/Liner-3.png)
   
   
   现在的问题是求解⍬,使得损失函数的值J(⍬)最小。
   
  

####方法一，用 *正规方程（The normal equations）* 计算：

 
  
   推导出结果为：
  
   ⍬ ![Mou icon](http://lexmao.com/images/Liner-4.png)
  
  
  
#####开始用octave 来计算：
  
  
   首先，由于x0=1，所以整理一下数据源为：
  
       X0               X1                 Y
  
   ![Mou icon](http://lexmao.com/images/Liner-5.png)
  
   *  导入数据
       
     ![Mou icon](http://lexmao.com/images/Liner-6.png)
      

   * 获得X及其倒置
  
  
     ![Mou icon](http://lexmao.com/images/Liner-7.png)
    
  
     ![Mou icon](http://lexmao.com/images/Liner-8.png)
    

   * 计算 (Xt*X)的逆


      ![Mou icon](http://lexmao.com/images/Liner-9.png)



   * 获得Y

      ![Mou icon](http://lexmao.com/images/Liner-10.png)
   
   * 最后计算⍬

      ![Mou icon](http://lexmao.com/images/Liner-11.png)
   


   所以，最后的回归方程为
   
   *y = 3.0077 + 1.6953x*
   
   
   如果有新的输入变量x，需要预估出y值，带入上面方程即可获得。
   
   
   
####方法二，用梯度下降来获得使得J(⍬)的最小值的⍬值

    
   对于我们的损失函数J(θ)求偏导J：
   
   
   ![Mou icon](http://lexmao.com/images/Liner-12.png)
   
   θi表示更新之前的值，-后面的部分表示按梯度方向减少的量，α表示步长，也就是每次按照梯度减少的方向变化多少

   ![Mou icon](http://lexmao.com/images/Liner-13.png)
   
   
#####开始用octave计算：
   
   
   解释下面octave:19行的含义：
   
   R是我们求的回归方程的解；先初始化为[0,0] 
   
   然后循环100次，执行 R=R-0.001*Xt*(X*R-Y)
   
   0.001是步长参数，可以调节；
   
   X*R 是根据R获得的结果，X*R -Y 其实就是误差。
   
   只是上面都是向量／矩阵结算。
   

 
   ![Mou icon](http://lexmao.com/images/Liner-15.png)


   ![Mou icon](http://lexmao.com/images/Liner-16.png)
   
   执行到最后，R=[3.0373,1.6388]，这就是我们的结果，
   
   当循环增加到200次的时候，R=[3.0109,1.6893]
   
   当循环增加到500次的时候，R=[3.0078,1.6952]
   
   所以，回归方程为：
   
   *y=3.0078 + 1.6952x*
    
    
    
   最后，关于验证等工作就不再描述了。
    
    
   


 
