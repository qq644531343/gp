//
//  ViewController.h
//  TestCocoa
//
//  Created by libo on 15/6/23.
//  Copyright (c) 2015年 libo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController
@property (weak) IBOutlet NSTextField *labelScore;
@property (weak) IBOutlet NSTextField *labelPercent;
@property (weak) IBOutlet NSTextField *labelCrease;

@property (weak) IBOutlet NSTextField *labelSubmit;
@property (weak) IBOutlet NSTextField *labelBegin;
@property (weak) IBOutlet NSTextField *fieldTime;
@property (weak) IBOutlet NSTextField *fieldCode;

@property (weak) IBOutlet NSTextField *logLabel;
@property (strong) IBOutlet NSButton *checkbox;

@property (strong) NSDate *lastPushDate;
@property (readwrite) double lastPercent;

@end

