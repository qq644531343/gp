//
//  MyWindow.m
//  TestCocoa
//
//  Created by libo on 15/6/23.
//  Copyright (c) 2015年 libo. All rights reserved.
//

#import "MyWindow.h"

@implementation MyWindow

-(void)close
{
    [[NSRunningApplication currentApplication] terminate];
}

-(instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    if(self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag]){
    }
    return self;
}


@end
