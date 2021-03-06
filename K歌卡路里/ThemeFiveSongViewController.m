//
//  ThemeFiveSongViewController.m
//  K歌卡路里
//
//  Created by amber on 15/2/7.
//  Copyright (c) 2015年 amber. All rights reserved.
//

#import "UIImageView+WebCache.h"
#import "ThemeSongListCell.h"
#import "SDWebImageDownloader.h"
#import "SingViewController.h"
#import "ThemeFiveSongViewController.h"
#import "SongListTableViewCell.h"

#define kLoadLableNotification @"kLoadLableNotification"
#define FileSavePath [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]

@implementation ThemeFiveSongViewController
- (id)init
{
    self = [super init];
    if (self) {
        self.title = @"然后呢?一起走吧";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initTableView];
    [self initURLSource];
    [self initURL];
    
    activityView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:    UIActivityIndicatorViewStyleGray];
    [self startViewLoading];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    self.navigationController.navigationBarHidden = YES;
    self.navigationController.toolbarHidden = NO;
    [self toolbarShow];
    [self cellLinLeft];
        
    filesPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/DownLoad"];
    [self downloadPath];
}

#pragma mark -- UI
-(void)initTableView
{
    _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, -20, ScreenWidth, ScreenHeight+15) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = NO;   //是否需要显示分割线
    _tableView.allowsSelection = NO;  //是否允许选中cell
    
    self.navigationController.navigationBarHidden = YES;
    [self.view addSubview:_tableView];
}

- (void)toolbarShow
{
    
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"toolbar_back.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(backAction)];
    
    NSArray *items = @[backItem];
    
    self.navigationController.toolbar.frame = CGRectMake(0, self.view.height - 49, self.view.width, 49);
    self.toolbarItems = items;
}

- (void)showText:(ThemeSongListCell *)cell
{
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.width, 85)];
    UITextView *textView = [[UITextView alloc]initWithFrame:CGRectMake(0, 0, self.view.width, 85)];
    textView.text = @"每个人心中都有一个自己的小曲库，即使K歌的次数早已多的数不清，而那些曾经给予你感动、带给你力量、让你热泪盈眶的歌曲，仍然时常会在你的耳边响起.....";
    textView.editable = NO;
    textView.selectable = NO;
    textView.textColor = [UIColor grayColor];
    textView.font = [UIFont systemFontOfSize:14];
    [view addSubview:textView];
    [cell.contentView addSubview:view];
}

- (void)cellLinLeft
{
    UIEdgeInsets inset;
    inset.left = 0;
    [_tableView setSeparatorInset:inset];
}

#pragma mark -- HTTP
- (void)initURLSource
{
    urlStr =  @"http://120.27.49.100:8000/res/cover/";
    songStr = @"http://120.27.49.100:8000/res/mp3/";
    lrcStr  = @"http://120.27.49.100:8000/res/lrc/";
}

#pragma mark -- action
- (void)backAction
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)startViewLoading
{
    activityView.frame = CGRectMake(ScreenWidth/2-20, ScreenHeight/2-100, 50, 50);
    [_tableView addSubview:activityView];
    _tableView.scrollEnabled = NO;   //禁止手滚动cell
    [activityView startAnimating];
    //正在加载的label
    loaingLabel = [[UILabel alloc]initWithFrame:CGRectMake(ScreenWidth/2-50, ScreenHeight/2-50, 60, 40)];
    loaingLabel.backgroundColor = [UIColor clearColor];
    loaingLabel.font = [UIFont systemFontOfSize:15.0f];
    loaingLabel.textColor = [UIColor blackColor];
    loaingLabel.text = @"正在玩命加载中...";
    [loaingLabel sizeToFit];
    [_tableView addSubview:loaingLabel];
}

- (void)stopViewLoading
{
    [activityView stopAnimating];
    _tableView.scrollEnabled = YES;
    UIImageView *imageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"005"]];
    _tableView.tableHeaderView = imageView;
    [loaingLabel removeFromSuperview];
}

- (void)songLoadAction:(UIButton *)button
{
    NSDictionary* urlDic = [self.data  objectAtIndex:button.tag];
    self.urlString = [urlDic objectForKey:@"id"];
    self.songsName = [urlDic objectForKey:@"name"];
    self.singerName = [urlDic objectForKey:@"singer"];
    NSString *mp3Names = [NSString stringWithFormat:@"%@_01.mp3",self.urlString];
    BOOL isFile = [ThemeFiveSongViewController isFileExist:mp3Names];
    
    if (button.selected == NO && isFile == NO) {
        button.selected = YES;
        [button setTitle:nil forState:UIControlStateNormal];
        
        if (loadingLabel.text == nil || [_loadProgress isEqualToString:@"100%"]) {
            [self startDownloadMP3:button];
            [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(notifShow) name:kLoadLableNotification object:nil];
            loadingLabel = [[UILabel alloc]initWithFrame:CGRectMake(12, -1, 40, 30)];
            loadingLabel.textColor = [UIColor orangeColor];
            loadingLabel.text = @"0%";
            loadingLabel.textAlignment = UITextAlignmentCenter;
            loadingLabel.font = [UIFont systemFontOfSize:13];
            [button addSubview:loadingLabel];
        }else{
            [button setTitle:@"点歌" forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont systemFontOfSize:13];
            button.selected = NO;
            UIAlertView *titleAlert = [[UIAlertView alloc]initWithTitle:nil message:@"对不起，你还有歌曲正在下载中,请下载完后再点歌" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [titleAlert show];
        }
        
    }else if (isFile == YES){
        [self currentTimeShow];
        singVC = [[SingViewController alloc]init];
        singVC.urlString = self.urlString;
        singVC.songsName = self.songsName;
        singVC.singerName = self.singerName;
        singVC.recordName = self.recordName;
        singVC.recordTime = self.recordTime;
        singVC.recordTimeValue = self.recordTimeValue;
        
        [button setTitle:@"演唱" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor orangeColor]forState:UIControlStateNormal];
        [button setBackgroundImage:[UIImage imageNamed:@"songDownloadSelectBtn.png"] forState:UIControlStateNormal];
        [kNavigationController pushViewController:singVC animated:YES];
        
    }else if (button.selected == YES)
    {
        alertView = [[UIAlertView alloc]initWithTitle:nil message:@"歌曲正在下载中,无法取消哦" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
    }
}

- (void)notifShow
{
    loadingLabel.text = _loadProgress;
    //NSLog(@"%@",_loadProgress);
    //arrayData = [NSMutableArray arrayWithObjects:_loadProgress,_songName,_singger,nil];
    //NSLog(@"%@",arrayData);
    
    if ([loadingLabel.text isEqualToString:@"100%"]) {
        loadingLabel.text = @"演唱";
        //NSLog(@"下载完成");
        return;
    }
}


#pragma mark -- data
- (void)initURL
{
    NSString *pathStr = @"http://120.27.49.100:8000/api/get_songs_by_category/?category=2";
    NSURL    *url = [NSURL URLWithString:pathStr];
    _request = [[ASIHTTPRequest alloc]initWithURL:url];
    _request.tag = 1001;
    _request.delegate = self;
    [_request setRequestMethod:@"GET"];
    [_request setTimeOutSeconds:60];
    [_request startAsynchronous];
}

- (void)startDownloadMP3:(UIButton *)button
{
    NSDictionary* urlDic = [self.data  objectAtIndex:button.tag];
    urlFileStr = [urlDic objectForKey:@"id"];
    NSString *songFile = [NSString stringWithFormat:@"%@%@_01.mp3",songStr,urlFileStr];
    NSString *lrcFile = [NSString stringWithFormat:@"%@%@.lrc",lrcStr,urlFileStr];
    
    NSURL *songURL = [NSURL URLWithString:songFile];
    NSURL *lrcURL = [NSURL URLWithString:lrcFile];
    
    if (!networkQueue) {
        networkQueue = [[ASINetworkQueue alloc] init];
    }
    [networkQueue setShowAccurateProgress:YES]; // 进度精确显示
    [networkQueue setDelegate:self]; // 设置队列的代理对象
    [networkQueue setMaxConcurrentOperationCount:1];   //设置最大并发连接数，也就是同时几个任务在下载
    
    //初始化保存路径
    NSString *saveMP3Path = [FileSavePath  stringByAppendingPathComponent:[NSString stringWithFormat:@"DownLoad/%@_01.mp3",urlFileStr]];
    NSString *saveLRCPath = [FileSavePath  stringByAppendingPathComponent:[NSString stringWithFormat:@"DownLoad/%@.lrc",urlFileStr]];
    
    _loadRequest = [ASIHTTPRequest requestWithURL:songURL];
    _loadRequest.delegate = self;
    _loadRequest.tag = 1002;
    
    _loadLRCRequest = [ASIHTTPRequest requestWithURL:lrcURL];
    _loadLRCRequest.delegate = self;
    _loadLRCRequest.tag = 1003;
    
    //	//初始化临时文件路径，就是将mp3先放到DownLoad/temp/这个目录，等下载完后再放到DownLoad目录
    NSString *tempMP3Path = [FileSavePath stringByAppendingPathComponent:[NSString stringWithFormat:@"DownLoad/temp/%@_01.mp3.temp",urlFileStr]];
    NSString *tempLRCPath = [FileSavePath stringByAppendingPathComponent:[NSString stringWithFormat:@"DownLoad/temp/%@.lrc.temp",urlFileStr]];
    
    if (_loadRequest) {
        //设置文件保存路径，就是将mp3先放到DownLoad/temp/这个目录，等下载完后再放到DownLoad目录
        [_loadRequest setDownloadDestinationPath:saveMP3Path];
        //设置临时文件路径
        [_loadRequest setTemporaryFileDownloadPath:tempMP3Path];
        //设置进度条的代理,
        [_loadRequest setDownloadProgressDelegate:self];
        //设置是是否支持断点下载
        //[_loadRequest setAllowResumeForFileDownloads:YES];
        
        [networkQueue addOperation:_loadRequest];  //添加队列对象
        [networkQueue go];     //开始队列
    }
    
    if (_loadLRCRequest) {
        [_loadLRCRequest setDownloadDestinationPath:saveLRCPath];
        [_loadLRCRequest setTemporaryFileDownloadPath:tempLRCPath];
        [networkQueue addOperation:_loadLRCRequest];
        [networkQueue go];
    }
    
    
    //NSLog(@"%@",songFile);
    //NSLog(@"%@",lrcFile);
}

#pragma mark -- ASIHTTPRequestDelegate
//ASIHTTPRequestDelegate,下载之前获取信息的方法,主要获取下载内容的大小，可以显示下载进度多少字节
- (void)request:(ASIHTTPRequest *)request didReceiveResponseHeaders:(NSDictionary *)responseHeaders {
    if (request.tag == 1002){
        //下载新任务前清空上一个任务下载的数据量
        self.downLoadLenth = 0;
        
        double fileLenth = [[responseHeaders valueForKey:@"Content-Length"] doubleValue];
        self.fileSiz = fileLenth;
    }
}
//下载中,显示下载的进度条
- (void)request:(ASIHTTPRequest *)request didReceiveBytes:(long long)bytes {
    if (request.tag == 1002){
        self.downLoadLenth += bytes;
        double progress = self.downLoadLenth / self.fileSiz;
        _loadProgress = [NSString stringWithFormat:@"%.0f%%",progress * 100];
        //NSLog(@"%@",loadProgress);
        [[NSNotificationCenter defaultCenter]postNotificationName:kLoadLableNotification object:nil];
    }
}

- (void)requestFinished:(ASIHTTPRequest *)request {
    if (request.tag == 1001) {
        NSData *responseData = [request responseData];
        self.data = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
        [_tableView reloadData];
        _tableView.separatorStyle = YES;
        _tableView.hidden = NO;
        
        [self stopViewLoading];
    }
}

//请求失败
- (void)requestFailed:(ASIHTTPRequest *)request {
    NSError *error = request.error;
    NSLog(@"请求网络出错：%@",error);
    if (request.tag == 1002){
        UIAlertView *alertView1 = [[UIAlertView alloc]initWithTitle:@"温馨提醒" message:@"请求超时，请点击取消重新下载" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [alertView1 show];
    }
}

#pragma mark -- UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identify =  [NSString stringWithFormat:@"cell%d",indexPath.row];
    ThemeSongListCell *cell = [tableView dequeueReusableCellWithIdentifier:identify];
    if (cell == nil) {
        cell = [[ThemeSongListCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identify];
        
        if (indexPath.row == 0) {
            [self showText:cell];
        }else if (indexPath.row != 0) {
            NSDictionary *dic = [self.data objectAtIndex:indexPath.row - 1];
            _songName  = [dic objectForKey:@"name"];
            _singger   = [dic objectForKey:@"singer"];
            _songID = [dic objectForKey:@"id"];
            NSString *songImageName = [NSString  stringWithFormat:@"%@%@.jpg",urlStr,_songID];
            [cell.imageView setImageWithURL:[NSURL URLWithString:songImageName]placeholderImage:[UIImage imageNamed:@"default_CDimage.png"]];
            
            UIColor *color = [UIColor colorWithRed:54.0/255 green:53.0/255 blue:52.0/255 alpha:1];
            cell.textLabel.textColor = color;
            cell.detailTextLabel.textColor = [UIColor grayColor];
            
            //cell中显示的文字距离
            int cellHeight = cell.frame.size.height;
            int cellWidth = cell.frame.size.width;
            cell.textLabel.frame = CGRectMake(70, -5 , cellWidth, cellHeight-10);
            cell.detailTextLabel.frame = CGRectMake(70, 20, cellWidth, cellHeight-10);
            cell.textLabel.font = [UIFont systemFontOfSize:16];
            UIColor *textColor = [UIColor colorWithRed:42.0/255.0 green:42.0/255.0 blue:42.0/255.0 alpha:1.0];
            cell.textLabel.textColor = textColor;
            
            cell.textLabel.text = _songName;
            cell.detailTextLabel.text = _singger;
            
            UIButton *songLoadBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            songLoadBtn.frame = CGRectMake(ScreenWidth - 75, 19, 64, 29);
            [songLoadBtn setBackgroundImage:[UIImage imageNamed:@"songDownload_Butnon.png"] forState:UIControlStateNormal];
            [songLoadBtn setBackgroundImage:[UIImage imageNamed:@"songDownloadSelectBtn.png"] forState:UIControlStateSelected];
            [songLoadBtn setTitle:@"点歌" forState:UIControlStateNormal];
            songLoadBtn.titleLabel.font = [UIFont systemFontOfSize:13];
            //songLoadBtn.tag = 201;
            songLoadBtn.selected = NO;
            [songLoadBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            [songLoadBtn addTarget:self action:@selector(songLoadAction:) forControlEvents:UIControlEventTouchUpInside];
            //[cell.contentView addSubview:songLoadBtn];
            cell. accessoryView = songLoadBtn;
            songLoadBtn.tag = indexPath.row - 1 ;
        }
    }
    
    return cell;
}

- (void)timerAction:(NSString *)url withCell:(ThemeSongListCell *)cell
{
    /*
     UIImageView *image = [[UIImageView alloc]init];
     [image setImageWithURL:[NSURL URLWithString:url]placeholderImage:[UIImage imageNamed:@"default_CDimage.png"]];
     
     CGSize itemSize = CGSizeMake(55, 55);
     UIGraphicsBeginImageContextWithOptions(itemSize, NO ,0.0);
     CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
     [image.image drawInRect:imageRect];
     
     cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
     UIGraphicsEndImageContext();
     */
    [cell.imageView setImageWithURL:[NSURL URLWithString:url]placeholderImage:[UIImage imageNamed:@"default_CDimage.png"]];
    [_tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        return 78;
    }else{
        return 65;
    }
}

#pragma mark -- other
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];
    self.navigationController.toolbarHidden = YES;
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [_request cancel];
    [_loadRequest cancel];
    [_loadLRCRequest cancel];
}

//设置下载MP3的路径
- (void)downloadPath
{
    // 创建存放路径
    //初始化Documents路径
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    //初始化临时文件路径
    NSString *folderPath = [path stringByAppendingPathComponent:@"/DownLoad/temp"];
    //创建文件管理器
    fileManager = [NSFileManager defaultManager];
    //判断temp文件夹是否存在
    BOOL fileExists = [fileManager fileExistsAtPath:folderPath];
    
    if (!fileExists) {//如果不存在说创建,因为下载时,不会自动创建文件夹
        [fileManager createDirectoryAtPath:folderPath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
    }
}

//判断沙盒中是否有该文件存在
+ (BOOL)isFileExist:(NSString *)fileNames
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDir = [docPaths objectAtIndex:0];
    NSString *sourcePath = [NSString stringWithFormat:@"%@/DownLoad/",documentDir];
    NSString *filesPaths = [sourcePath stringByAppendingFormat:fileNames,nil];
    BOOL result = [fileManager fileExistsAtPath:filesPaths];
    return result;
}

- (void)currentTimeShow
{
    NSDateFormatter *nsdf2=[[NSDateFormatter alloc] init];
    [nsdf2 setDateStyle:NSDateFormatterShortStyle];
    [nsdf2 setDateFormat:@"YYYYMMDDHHmmss"];
    NSString *date=[nsdf2 stringFromDate:[NSDate date]];
    self.recordName = [NSString stringWithFormat:@"%@ID%@.caf",date,self.urlString];
    self.recordTime = date;
    NSLog(@"timer:%@",self.recordTime);
    
    NSDateFormatter *nsdf3=[[NSDateFormatter alloc] init];
    [nsdf3 setDateStyle:NSDateFormatterShortStyle];
    [nsdf3 setDateFormat:@"MM-dd HH:mm"];
    NSString *date2=[nsdf3 stringFromDate:[NSDate date]];
    self.recordTimeValue = date2;
}


@end
