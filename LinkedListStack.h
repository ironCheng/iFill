//
//  LinkedListStack.h
//  iFill
//
//  Created by iRon_iMac on 2018/7/10.
//  Copyright © 2018年 iRon_. All rights reserved.
//

#import <Foundation/Foundation.h>

#define Final_Node_Offset -1
#define Invalid_Node_Content INT_MIN

typedef struct PointNode {
    NSInteger nextNodeOffset;
    NSInteger point;
} PointNode;

@interface LinkedListStack : NSObject

- (id)initWithCapacity:(NSInteger)capacity incrementSize:(NSInteger)increment multiplier:(NSInteger)mul;
- (id)initWithCapacity:(NSInteger)capacity;

- (void)pushFrontX:(NSInteger)x andY:(NSInteger)y;
- (NSInteger)popFront:(NSInteger *)x andY:(NSInteger *)y;

@end
