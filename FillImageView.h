//
//  FillImageView.h
//  iFill
//
//  Created by iRon_iMac on 2018/7/12.
//  Copyright © 2018年 iRon_. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FillImageView : UIImageView

/*
 *  需要填充的颜色
 */
@property (nonatomic, strong) UIColor *newcolor;
/*
 *  缩放比例
 */
@property (nonatomic, assign) CGFloat scaleNum;

/*
 *  撤销
 */
- (void)revokeOption;

@end
