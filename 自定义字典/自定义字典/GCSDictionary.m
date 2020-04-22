//
//  GCSDictionary.m
//  自定义字典
//
//  Created by EDZ on 2020/4/20.
//  Copyright © 2020 EDZ. All rights reserved.
//

#import "GCSDictionary.h"
#import "Node.h"

struct NodeInfo {
    Node * node;
    NSUInteger index;
};
typedef struct NodeInfo NodeInfo;

@interface GCSDictionary ()

/// 里面都是Node类型
@property (nonatomic,strong) NSPointerArray * dataArray ;
/// 当前的最大容量
@property (nonatomic,assign) NSUInteger totleCount ;
/// 当前的数量
@property (nonatomic,assign) NSUInteger currentCount ;

@end


@implementation GCSDictionary

- (instancetype)init {
    self = [super init];
    if (self) {
        self.totleCount = 16;
        self.currentCount = 0;
        self.dataArray = [[NSPointerArray alloc] initWithOptions:NSPointerFunctionsStrongMemory];
        // 会把前面的都初始化为nil
        self.dataArray.count = self.totleCount;
    }
    return self;
}


/// 对外使用,增加新值,修改值,删除值
- (void)gcs_setObject:(id)anObject forKey:(NSString *)aKey {
    
    NSAssert(aKey, @"key不能为空");
    //删除值
    if (anObject == nil) {
        [self gcs_removeObjectForKey:aKey];
        return;
    }
    
    
    NodeInfo info = [self getNodeInfoWithKey:aKey];
    // 更新值
    if (info.node) {
        info.node.value = anObject;
        return;
    }
    // 插入一个新值
    Node * currentNode = [self.dataArray pointerAtIndex:info.index];
    Node * newNode = [[Node alloc] init];
    newNode.key = aKey;
    newNode.value = anObject;
    newNode.nextNode = currentNode;
    self.currentCount ++;
    [self.dataArray replacePointerAtIndex:info.index withPointer:(__bridge void * _Nullable)(newNode)];
    if (self.currentCount >= self.totleCount*3/4) {
        [self rebuildGCSDictionary];
    }
    
    
}
/// 对外使用,根据key查找值
- (id)gcs_objectForKey:(NSString *)aKey {
    NodeInfo info = [self getNodeInfoWithKey:aKey];
    return info.node.value;
}

/// 对外使用,根据key删除值
- (void)gcs_removeObjectForKey:(NSString *)aKey{
    if (aKey == nil) {
        return ;
    }
    NodeInfo info = [self getNodeInfoWithKey:aKey];
    if (info.node == nil) {
        NSLog(@"此%@节点不存在对应的value",aKey);
        return;
    }
    
    Node * preNode = [self.dataArray pointerAtIndex:info.index];
    // 如果要移除的是第一个node,那dataArray就替换成nextNode即可
    // 如果移除的是中间的node,dataArray把前一个的nextNode指向移除node的nextNode
    // 如果移除的是最后的node,dataArray把前一个的nextNode指向nil即可
    // 中间的和最后的可以合成一个
    if ([preNode isEqual:info.node]) {
        self.currentCount --;
        [self.dataArray replacePointerAtIndex:info.index withPointer:(__bridge void * _Nullable)(info.node.nextNode)];
        if (self.currentCount <= self.totleCount/4) {
            [self rebuildGCSDictionary];
        }
        return;
    }
    
    while (preNode) {
        if ([preNode.nextNode isEqual:info.node]) {
            self.currentCount --;
            preNode.nextNode = info.node.nextNode;
            if (self.currentCount <= self.totleCount/4) {
                [self rebuildGCSDictionary];
            }
            return;
        }
    }
    
}


// 内部使用,根据key获取到对应的node和下标,
- (NodeInfo)getNodeInfoWithKey:(NSString *)key {
    NodeInfo info ;
    NSUInteger index = [self getIndexWithKey:key];
    
    Node * resultNode = nil;
    Node * currentNode = [self.dataArray pointerAtIndex:index];
    while (currentNode) {
        if ([currentNode.key isEqualToString:key]) {
            resultNode = currentNode;
            break;
        }
        currentNode = currentNode.nextNode;
    }
    
    info.node = resultNode;
    info.index = index;
    return info;
}

// 内部使用,根据key获取到对应的下标,
- (NSUInteger)getIndexWithKey:(NSString *)key {
    // 方式1,使用系统的hash算法
    NSUInteger hash = [key hash];
    NSUInteger index = hash % self.totleCount;
    return index;
    
    
}

// 内部使用,重新构造数组
- (void)rebuildGCSDictionary {
    // 检查是否需要扩容
    if (self.currentCount >= self.totleCount*3/4) {
        self.totleCount *= 2;
    } else if(self.currentCount <= self.totleCount/4&&self.totleCount > 16) { //totleCount最小为16, && <总量的1/4  ,缩小
        self.totleCount /= 2;
    } else {
        return;
    }
    
    // 需要扩容/缩小,先保存旧的数组,然后重新构建一个数组,
    NSPointerArray * oldArray = [self.dataArray copy];
    self.currentCount = 0;
    self.dataArray = [[NSPointerArray alloc] initWithOptions:NSPointerFunctionsStrongMemory];
    self.dataArray.count = self.totleCount;
    for (int i = 0; i<oldArray.count; i++) {
        
        Node * currentNode = [oldArray pointerAtIndex:i];
        while (currentNode) {
            [self gcs_setObject:currentNode.value forKey:currentNode.key];
            currentNode = currentNode.nextNode;
        }
        
    }
    
    
    
    
}


- (NSString *)description {
    NSMutableDictionary * dic = [NSMutableDictionary dictionary];
    
    for (int i = 0 ; i<self.dataArray.count; i++) {
        Node * currentNode = [self.dataArray pointerAtIndex:i];
        while (currentNode) {
            dic[currentNode.key] = currentNode.value;
            currentNode = currentNode.nextNode;
        }
        
    }
    
    return [NSString stringWithFormat:@"%@ %@",@(dic.count),dic];
}

- (NSString *)dataArrayDescription {
    
    NSMutableString * str = [NSMutableString string];
    for (int i = 0 ; i<self.dataArray.count; i++) {
        Node * currentNode = [self.dataArray pointerAtIndex:i];
        [str appendFormat:@"%@ %@\n",@(i),currentNode];
    }
    return str;
}

@end
