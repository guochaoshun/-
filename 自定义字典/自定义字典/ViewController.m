//
//  ViewController.m
//  自定义字典
//
//  Created by EDZ on 2020/4/20.
//  Copyright © 2020 EDZ. All rights reserved.
//

#import "ViewController.h"
#import "GCSDictionary.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    

//    [self multiThreadTest];
    [self oneThreadTest];


}

// 多线程测试用例
- (void)multiThreadTest {
    
    GCSDictionary * dic = [[GCSDictionary alloc] init];
    
    // 增加,触发扩容
    for (int i = 0; i<20; i++) {
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSString * key = [NSString stringWithFormat:@"%@",@(i)];
            [dic gcs_setObject:key forKey:key];
        });
        
    }
    
    for (int i = 0; i<20; i++) {
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSString * key = [NSString stringWithFormat:@"%@",@(i)];
            [dic gcs_setObject:@"111" forKey:key];
        });
        
    }
    NSLog(@"%@",dic);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"%@",dic);

    });
}

// 单线程的测试用例
- (void)oneThreadTest {
    
    GCSDictionary * dic = [[GCSDictionary alloc] init];
    
    // 增加,触发扩容
    for (int i = 0; i<20; i++) {
        NSString * key = [NSString stringWithFormat:@"%@",@(i)];
        [dic gcs_setObject:key forKey:key];
    }
    NSLog(@"%@",dic);
    
    // 修改
    [dic gcs_setObject:@"5555" forKey:@"5"];
    NSLog(@"%@",dic);

    
    // 删除
    [dic gcs_setObject:nil forKey:@"100"];
    [dic gcs_setObject:nil forKey:@"10"];
    NSLog(@"%@",dic);

    [dic gcs_removeObjectForKey:@"11"];
    NSLog(@"%@",dic);

    // 查找
    NSLog(@"%@",[dic gcs_objectForKey:@"12"]);
    NSLog(@"%@",dic);

    //减少,触发缩表
    for (int i = 5; i<20; i++) {
        NSString * key = [NSString stringWithFormat:@"%@",@(i)];
        [dic gcs_removeObjectForKey:key];
    }
    
    NSLog(@"%@",dic);
    
    
}




@end
