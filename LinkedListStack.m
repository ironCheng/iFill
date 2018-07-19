//
//  LinkedListStack.m
//  iFill
//
//  Created by iRon_iMac on 2018/7/10.
//  Copyright © 2018年 iRon_. All rights reserved.
//

#import "LinkedListStack.h"

@interface LinkedListStack ()
{
    /* 用NSData储存所有的node数据 */
    NSMutableData *nodesCache;
    
    NSInteger freeNodeOffset;
    NSInteger topNodeOffset;
    NSInteger _cacheSizeIncrements;
    
    NSInteger multiplier;
}

@end

@implementation LinkedListStack

#pragma mark - System Method

- (id)init
{
    return [self initWithCapacity:500];
}

#pragma mark - Public Method

- (id)initWithCapacity:(NSInteger)capacity
{
    return [self initWithCapacity:capacity incrementSize:500 multiplier:1000];
}

- (id)initWithCapacity:(NSInteger)capacity incrementSize:(NSInteger)increment multiplier:(NSInteger)mul
{
    self = [super init];
    if (self) {
        _cacheSizeIncrements = increment;
        NSInteger bytesRequired = capacity * sizeof(PointNode);
        nodesCache = [[NSMutableData alloc] initWithLength:bytesRequired];
        
        /* 从0开始初始化 */
        [self initNodesAtOffset:0 count:capacity];
        
        freeNodeOffset = 0;
        topNodeOffset = Final_Node_Offset;
        
        multiplier = mul;
    }
    return self;
}

- (void)pushFrontX:(NSInteger)x andY:(NSInteger)y
{
    // x乘以一个数，便于储存 x = p / mul; y = p % mul;
    NSInteger p = multiplier * x + y;
    PointNode *node = [self getNextFreeNode];
    node -> point = p;
    node -> nextNodeOffset = topNodeOffset;
    
    topNodeOffset = [self offsetOfNode:node];
}

- (NSInteger)popFront:(NSInteger *)x andY:(NSInteger *)y
{
    if (topNodeOffset == Final_Node_Offset) {
        return Invalid_Node_Content;
    }
    PointNode *node = [self nodeAtOffset:topNodeOffset];
    NSInteger thisNodeOffset = topNodeOffset;
    
    // Remove this node from the queue
    topNodeOffset = node -> nextNodeOffset;
    NSInteger value = node -> point;
    
    node -> point = 0;
    node -> nextNodeOffset = freeNodeOffset;
    
    freeNodeOffset = thisNodeOffset;
    
    *x = value / multiplier;
    *y = value % multiplier;
    
    return value;
}

#pragma mark - Privated Method

/* 从某个点开始初始化 */
- (void)initNodesAtOffset:(NSInteger)offset count:(NSInteger)count
{
    PointNode *node = (PointNode *)nodesCache.mutableBytes + offset;
    for (int i = 0; i < count - 1; i++) {
        node->point = 0;
        node->nextNodeOffset = offset + i + 1;
        // 指针++ 因为NSData的指针是顺序递增的。
        node++;
    }
    
    /* 最后一个node指向final */
    node->point = 0;
    node->nextNodeOffset = Final_Node_Offset;
}

- (PointNode *)getNextFreeNode
{
    if (freeNodeOffset < 0) {
        NSInteger currentSize = nodesCache.length / sizeof(PointNode);
        /* 增加一部分长度 */
        [nodesCache increaseLengthBy:_cacheSizeIncrements * sizeof(PointNode)];
        
        [self initNodesAtOffset:currentSize count:_cacheSizeIncrements];
        freeNodeOffset = currentSize;
    }
    
    // nodesCache.mutableBytes 所有数据的初始点
    PointNode *node = (PointNode *)nodesCache.mutableBytes + freeNodeOffset;
    freeNodeOffset = node->nextNodeOffset;
    
    return node;
}

- (NSInteger)offsetOfNode:(PointNode *)node
{
    // nodesCache.mutableBytes 所有数据的初始点
    return node - (PointNode *)nodesCache.mutableBytes;
}

- (PointNode *)nodeAtOffset:(NSInteger)offset
{
    return (PointNode *)nodesCache.mutableBytes + offset;
}

@end
