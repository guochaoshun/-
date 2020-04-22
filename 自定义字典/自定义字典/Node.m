//
//  Node.m
//  自定义字典
//
//  Created by EDZ on 2020/4/20.
//  Copyright © 2020 EDZ. All rights reserved.
//

#import "Node.h"

@implementation Node

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@:%@> %@",self.key,self.value,self.nextNode];
}

- (void)dealloc {
//    NSLog(@"%s",__func__);
}

@end
