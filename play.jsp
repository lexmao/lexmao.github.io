<style>
h1,
h2,
h3,
h4,
h5,
h6,
p,
blockquote {
    margin: 0;
    padding: 0;
}
body {
    font-family: "Helvetica Neue", Helvetica, "Hiragino Sans GB", Arial, sans-serif;
    font-size: 13px;
    line-height: 18px;
    color: #737373;
    background-color: white;
    margin: 10px 13px 10px 13px;
}
table {
	margin: 10px 0 15px 0;
	border-collapse: collapse;
}
td,th {	
	border: 1px solid #ddd;
	padding: 3px 10px;
}
th {
	padding: 5px 10px;	
}

a {
    color: #0069d6;
}
a:hover {
    color: #0050a3;
    text-decoration: none;
}
a img {
    border: none;
}
p {
    margin-bottom: 9px;
}
h1,
h2,
h3,
h4,
h5,
h6 {
    color: #404040;
    line-height: 36px;
}
h1 {
    margin-bottom: 18px;
    font-size: 30px;
}
h2 {
    font-size: 24px;
}
h3 {
    font-size: 18px;
}
h4 {
    font-size: 16px;
}
h5 {
    font-size: 14px;
}
h6 {
    font-size: 13px;
}
hr {
    margin: 0 0 19px;
    border: 0;
    border-bottom: 1px solid #ccc;
}
blockquote {
    padding: 13px 13px 21px 15px;
    margin-bottom: 18px;
    font-family:georgia,serif;
    font-style: italic;
}
blockquote:before {
    content:"\201C";
    font-size:40px;
    margin-left:-10px;
    font-family:georgia,serif;
    color:#eee;
}
blockquote p {
    font-size: 14px;
    font-weight: 300;
    line-height: 18px;
    margin-bottom: 0;
    font-style: italic;
}
code, pre {
    font-family: Monaco, Andale Mono, Courier New, monospace;
}
code {
    background-color: #fee9cc;
    color: rgba(0, 0, 0, 0.75);
    padding: 1px 3px;
    font-size: 12px;
    -webkit-border-radius: 3px;
    -moz-border-radius: 3px;
    border-radius: 3px;
}
pre {
    display: block;
    padding: 14px;
    margin: 0 0 18px;
    line-height: 16px;
    font-size: 11px;
    border: 1px solid #d9d9d9;
    white-space: pre-wrap;
    word-wrap: break-word;
}
pre code {
    background-color: #fff;
    color:#737373;
    font-size: 11px;
    padding: 0;
}
sup {
    font-size: 0.83em;
    vertical-align: super;
    line-height: 0;
}
* {
	-webkit-print-color-adjust: exact;
}
@media screen and (min-width: 914px) {
    body {
        width: 854px;
        margin:10px auto;
    }
}
@media print {
	body,code,pre code,h1,h2,h3,h4,h5,h6 {
		color: black;
	}
	table, pre {
		page-break-inside: avoid;
	}
}
</style>

*  ### 看AI怎么生成漫画</title>

<p><a href="http://readai.me"><img src="http://readai.me/images/logo.png" alt="readai" /></a></p>

<hr />

<hr />

<ul>
<li><h3>看AI怎么生成漫画</h3>

<p>Posted June 23, 2017 by ReadAI</p>

<ul>
<li><h5>项目介绍</h5>

<p>作为一个二次元玩家，有时候有种冲动，想自己尝试创作一幅动漫美少女作品。</p>

<p>现在，AI让这个梦想可能成真，你不需要是一个画师，你只要把你喜欢的动漫图片喂给AI进行学习训练，它就可能给你创作 <br/>
出你期望的作品。这个技术是目前在深度学习领域比较热的主题：生成式对抗网络（GAN）。</p>

<p>关于GAN的paper 请参看Ian Goodfellow 的Generative Adversarial Networks（arxiv：https://arxiv.org/abs/1406.2661）</p>

<p>简单地描述原理： 在GAN体系中存在2个网络，一个是生成网络（Generator），一个是判别网络（Discriminator），它们就像 <br/>
一组矛和盾。用生成图片来说明它们的运作过程：生成网络(Generator)通过一些真实的图片数据集进行训练，然后开始创作一些  <br/>
根本不存在的图片，目标是尽量模仿真实存在的图片，然后提交给判别网络（Discriminator）进行判别。判别网络（Discriminator)   <br/>
的目标就是根据先前从真实图片集中学习到的能力来识别出生成网络（Generator)提交的图片的真假。在形成的这个博弈的过程中，   <br/>
生成网络模拟生成的图片越来越逼真，判别网络识别能力越来越强。最后，两者到达一种平衡，这个时候也是就获得了一个比较优秀   <br/>
的生成网络模型。 利用这个模型就能够开始生成图片。</p>

<p>作为一个生成模型，GAN最直接的应用，就是用于真实数据分布的建模和生成，比如生成一些图片、视频、音乐等。</p>

<p>本项目用来生成动漫美女图片。</p></li>
<li><h5>实验结果</h5>

<p> 生成过程中产生的结果如下：</p>

<p> <img src="http://readai.me/ai_projects/test11.png" width="320" alt="" /></p>

<p> 最终结果如下：</p>

<p>  <img src="http://readai.me/ai_projects/test11.png" width="320" alt="" /></p>

<p> 如果你感觉下面图片太小，不清楚，可以试试放大我的老婆2倍  waifu2x...</p></li>
<li><h5>项目代码</h5>

<p>Github Repo <a href="https://github.com/carpedm20/DCGAN-tensorflow">carpedm20/DCGAN-tensorflow</a></p></li>
</ul>
</li>
</ul>


<hr />

<ul>
<li><h3>看不清动漫美少女？试试waifu2x</h3>

<p>Posted June 23, 2017 by ReadAI</p>

<ul>
<li><h5>项目介绍</h5>

<p>waifu2x这个名字可出名了：请把老婆放大2倍....waifu 就是 wife嘛。</p>

<p>如果你喜欢的动漫美女图片太小，太模糊怎么办？这时候就该waifu2x出马了。</p>

<p>waifu2x是一个利用卷积神经网络技术专门针对动漫风格的图片进行无损放大的神器（放大2倍，降噪，柔和曲线....）</p></li>
<li><h5>实验结果</h5>

<p><a href="http://waifu2x.udp.jp/index.zh-CN.html">在线试用</a></p>

<p><img src="https://raw.githubusercontent.com/nagadomi/waifu2x/master/images/slide.png" width="640" alt="" /></p></li>
<li><h5>项目代码</h5>

<p>Github Repo <a href="https://github.com/nagadomi/waifu2x">nagadomi/waifu2x</a></p></li>
</ul>
</li>
</ul>


<hr />

<ul>
<li><h3>用R-CNN统计小狗数量</h3>

<p>Posted June 13, 2017 by ReadAI</p>

<ul>
<li><h5>项目介绍</h5>

<p>我们的目标是利用机器学习技术来实时统计视频中每个画面上目标物体的数量，比如当前画面中有多少个人，多少辆车、多少条 <br/>
小狗等。这过程中，通常采用把视频分解成多个图片，然后针对每张图片来处理上面的问题，所以，我们简化问题为：</p>

<p>   <em>利用什么样的技术，能够尽量精准地统计出下面这张图片上有多少条狗？</em></p>

<p><img src="http://readai.me/ai_projects/smail-dog.jpg" width="480" alt="" /></p></li>
<li><h5>实验结果</h5>

<p>在深度学习领域，有一个非常有意思的模型R-CNN(Region based Convolutional Neural Network)，可以用来识别      <br/>
图片上的目标并对目标进行定位。本例中利用Keras 来实现和执行这个模型。先看一下执行的效果（目标名称后面的数字是    <br/>
识别的概率）：</p>

<p><img src="http://readai.me/ai_projects/test03.jpg" width="480" alt="" /></p></li>
<li><h5>项目代码</h5>

<p>Github Repo <a href="https://github.com/softberries/keras-frcnn">softberries/keras-frcnn</a></p>

<p> 另外，谷歌2017年6月份开源了这方面的最新研究成果：<a href="https://github.com/tensorflow/models/tree/master/object_detection">Tensorflow Object Detection API</a></p></li>
</ul>
</li>
</ul>


<hr />

<ul>
<li><h3>Teaching Machines to Draw - 教机器学习画画</h3>

<p>Posted MAY 19, 2017 by ReadAI</p>

<ul>
<li><h5>项目介绍</h5>

<p>最近，使用神经网络来获得图像生成模型已经取得了重大进展。 这些大量的利用网络神经来进行图像建模和生成的工作，    <br/>
大部分都是针对低分辨率像素图像。然而，人类并不是通过一个个的像素来认识这个世界，而是对我们所所看到的事物进行    <br/>
高度的抽象来认识理解这个世界。 从很小的时候开始，我们通过用铅笔在一张纸来上画出所看到的东西来培养这种抽象能力。</p>

<p>  <em>机器是否能够学会这种能力呢？</em></p></li>
<li><h5>实验结果</h5>

<p>我们输入一些素描画，然后要求机器进行模仿，最后结果还是挺有意思的 ^*^</p>

<p><img src="http://readai.me/ai_projects/ai_project_001_01.png" width="640" alt="" /></p></li>
<li><h5>项目代码</h5>

<p>Github Repo <a href="http://blog.otoro.net/2017/05/19/teaching-machines-to-draw/">teaching-machines-to-draw</a></p></li>
</ul>
</li>
</ul>


<hr />

<ul>
<li><h3>看AI怎么玩flappy birds</h3>

<p>Posted MAY 11, 2017 by ReadAI</p>

<ul>
<li><h5>项目介绍</h5>

<p> Flappy birds是一款游戏，要求用户操纵一只小鸟安全穿过不断出现的柱子（障碍），小鸟飞的越远，获得的游戏分数越高。 <br/>
目标是要一个实现一个AI来操纵这只小鸟，看看是否比人玩的更好，刷出更高的分数。  <br/>
通常，类似这样的问题，可以是一个强化学习的过程，利用Q-learning算法来实现是最常见的方式。  <br/>
而本项目有意思的地方在于使用了遗传算法：首先上帝般地创造出50只小鸟，然后让它们去闯关实现选择淘汰，在这过程  <br/>
中不断变异和交叉，最后获得最厉害的AI小鸟。</p>

<p>  具体的理论在<a href="http://www.scholarpedia.org/article/Neuroevolution">这儿Neuroevolution</a></p>

<p>本项目另外一个有意思的地方在于用很少的 javascript代码就实现了全部 ~~</p></li>
<li><h5>实验结果</h5>

<p>要获得高分，有时候演化到11代，有时候20多代  ^*^</p>

<p><img src="https://github.com/xviniette/FlappyLearning/raw/gh-pages/img/flappy.png?raw=true" width="480" alt="" /></p></li>
<li><h5>项目代码</h5>

<p>Github Repo <a href="https://github.com/xviniette/FlappyLearning">xviniette/FlappyLearning</a></p></li>
</ul>
</li>
</ul>


<hr />
