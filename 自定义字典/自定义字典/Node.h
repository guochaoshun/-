//
//  Node.h
//  自定义字典
//
//  Created by EDZ on 2020/4/20.
//  Copyright © 2020 EDZ. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Node : NSObject

@property (nonatomic,copy) NSString * key ;
@property (nonatomic,strong) id value ;

@property (nonatomic,strong) Node * nextNode ;

@end

NS_ASSUME_NONNULL_END
