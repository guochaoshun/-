//
//  GCSThreadDictionary.h
//  自定义字典
//
//  Created by EDZ on 2020/4/22.
//  Copyright © 2020 EDZ. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


/// 利用读写锁,实现一下多线程字典
@interface GCSThreadDictionary : NSObject

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
