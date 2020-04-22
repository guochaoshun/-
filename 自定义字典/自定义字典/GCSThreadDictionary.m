//
//  GCSThreadDictionary.m
//  自定义字典
//
//  Created by EDZ on 2020/4/22.
//  Copyright © 2020 EDZ. All rights reserved.
//

#import "GCSThreadDictionary.h"
#import "Node.h"

struct NodeInfo {
    Node * node;
    NSUInteger index;
};
typedef struct NodeInfo NodeInfo;

@interface GCSThreadDictionary ()

/// 里面都是Node类型
@property (nonatomic,strong) NSPointerArray * dataArray ;
/// 当前的最大容量
@property (nonatomic,assign) NSUInteger totleCount ;
/// 当前的数量
@property (nonatomic,assign) NSUInteger currentCount ;

@property (nonatomic,strong) dispatch_queue_t readWriteLock ;

@end


@implementation GCSThreadDictionary


- (instancetype)init {
    self = [super init];
    if (self) {
        self.totleCount = 16;
        self.currentCount = 0;
        self.dataArray = [[NSPointerArray alloc] initWithOptions:NSPointerFunctionsStrongMemory];
        // 会把前面的都初始化为nil
        self.dataArray.count = self.totleCount;

        _readWriteLock = dispatch_queue_create("readWriteLock", DISPATCH_QUEUE_CONCURRENT);
        
        
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
    dispatch_barrier_async(self.readWriteLock, ^{
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

    });
    
    dispatch_barrier_async(self.readWriteLock, ^{
        if (self.currentCount >= self.totleCount*3/4) {
            [self rebuildGCSDictionary];
        }
    });
    
    
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
        NSLog(@"%@ 不存在对应的value",aKey);
        return;
    }
    dispatch_barrier_async(self.readWriteLock, ^{
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

    });
    
}


// 内部使用,根据key获取到对应的node和下标,
- (NodeInfo)getNodeInfoWithKey:(NSString *)key {
    __block NodeInfo info ;
    dispatch_sync(self.readWriteLock, ^{
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
        // resultNode可能为nil
        info.node = resultNode;
        info.index = index;

    });
    return info;
}

// 内部使用,根据key获取到对应的下标,
- (NSUInteger)getIndexWithKey:(NSString *)key {
    // 方式1,使用系统的hash算法
    NSUInteger hash = [key hash];
    NSUInteger index = hash % self.totleCount;
    return index;
    
    // 方式2,使用自定义的hash算法,取出每个字符,然后平方相加,取余即可
//    NSUInteger hash = 0;
//    const char * charArray = [key UTF8String];
//    for (int i = 0; charArray[i] != '\0'; i++) {
//        char oneChar = charArray[i];
//        hash += oneChar * oneChar;
//    }
//    NSUInteger index = hash % self.totleCount;
//    return index;
    
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
    dispatch_barrier_async(self.readWriteLock, ^{
        
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

    });
    
}


- (NSString *)description {
    
    __block NSString * result = nil;
    dispatch_barrier_sync(self.readWriteLock, ^{
        NSMutableDictionary * dic = [NSMutableDictionary dictionary];
           
           for (int i = 0 ; i<self.dataArray.count; i++) {
               Node * currentNode = [self.dataArray pointerAtIndex:i];
               while (currentNode) {
                   dic[currentNode.key] = currentNode.value;
                   currentNode = currentNode.nextNode;
               }
               
           }
           result = [NSString stringWithFormat:@"%@ %@ %@",@(self.currentCount),@(dic.count),dic];
    });
    return result;
   
}

- (NSString *)dataArrayDescription {
    
    return [self pointArrayDescription:self.dataArray];
}

- (NSString *)pointArrayDescription:(NSPointerArray *)pointArray {
    NSMutableString * str = [NSMutableString string];
    for (int i = 0 ; i<pointArray.count; i++) {
        Node * currentNode = [pointArray pointerAtIndex:i];
        [str appendFormat:@"%@ %@\n",@(i),currentNode];
    }
    return str;
}



@end
