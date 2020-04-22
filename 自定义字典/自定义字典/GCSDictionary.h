//
//  GCSDictionary.h
//  自定义字典
//
//  Created by EDZ on 2020/4/20.
//  Copyright © 2020 EDZ. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GCSDictionary : NSObject

/// 实现增删改查
/// 自定义hash算法
/// 拉链法解决hash冲突
/// 自动扩容或者缩小
- (void)gcs_setObject:(nullable id)anObject forKey:(NSString *)aKey;
- (id)gcs_objectForKey:(NSString *)aKey;
- (void)gcs_removeObjectForKey:(NSString *)aKey;


- (NSString *)dataArrayDescription ;

@end

NS_ASSUME_NONNULL_END
