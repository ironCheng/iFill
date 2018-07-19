//
//  ViewController.m
//  iFill
//
//  Created by iRon_iMac on 2018/7/9.
//  Copyright © 2018年 iRon_. All rights reserved.
//

#import "ViewController.h"
#import "FillImageView.h"

@interface ViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) FillImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
}

- (void)setupUI
{
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 64, screenW, screenW)];
    _scrollView.delegate = self;
    [self.view addSubview:self.scrollView];
    _imageView = [[FillImageView alloc] initWithFrame:_scrollView.bounds];
    self.imageView.image = [UIImage imageNamed:@"2.jpg"];
    self.imageView.scaleNum = _imageView.image.size.width / [UIScreen mainScreen].bounds.size.width;
    self.imageView.newcolor = [UIColor redColor];
    [self.scrollView addSubview:self.imageView];
    
    self.scrollView.contentSize = _imageView.frame.size;
    self.scrollView.minimumZoomScale = 1;
    self.scrollView.maximumZoomScale = 5;
    self.scrollView.userInteractionEnabled = YES;
    
    UIButton *revokeBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(_scrollView.frame)+20, 200, 40)];
    [revokeBtn addTarget:self action:@selector(revokeAction) forControlEvents:UIControlEventTouchUpInside];
    [revokeBtn setTitle:@"撤销" forState:UIControlStateNormal];
    [revokeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:revokeBtn];
}

- (void)revokeAction
{
    [self.imageView revokeOption];
}

/* 实现这个协议方法才可以缩放相应的view */
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _imageView;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
