//
//  ViewController.m
//  TestCocoa
//
//  Created by libo on 15/6/23.
//  Copyright (c) 2015年 libo. All rights reserved.
//

#import "ViewController.h"

#define printLog(format, ...) ([self printLog:format, ##__VA_ARGS__])

typedef enum {
    TYPE_Gupiao, //A股
    TYPE_Futrue, //国内期货
    TYPE_MEIGU,  //美股
    TYPE_Foreign,  //国外期货
    TYPE_GANGGU   //港股
}CODE_TYPE;

@interface ViewController ()<NSTextFieldDelegate>
{
    NSMutableURLRequest *request;
    NSTimeInterval interval;
    
    NSDateFormatter *df;
    
    //最新数据
    NSString *name;
    NSString *kaipan ;
    NSString *zuoshou ;
    NSString *dangqian ;
    NSString *max ;
    NSString *min ;
    NSString *chengjiao ;
    NSString *chengjiaoe ;
    NSString *buy1count ;
    NSString *sell1count ;
    NSString *buy1price ;
    NSString *sell1price;
}

@end;

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *lastCode = [[NSUserDefaults standardUserDefaults] valueForKey:@"lastCode"];
    if (lastCode.length == 0) {
        lastCode = @"000001";
    }

    interval = 2;
    self.fieldTime.floatValue = interval;
    self.fieldCode.stringValue = lastCode;
    self.fieldCode.delegate = self;
    df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"HH:mm:ss"];
    
    request = [[NSMutableURLRequest alloc] init];
    
    [self beginRequestLoop];
}

-(void)update
{
//    NSLog(@"update");
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        if (!connectionError) {
            [self parseData:data];
        }else{
            printLog(@"%@",@"网络错误");
        }
        
        
        [self performSelector:@selector(update) withObject:nil afterDelay:interval];
    }];
    
}

-(void)parseData:(NSData *)data
{
    @autoreleasepool {
         NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
        NSString *text = [[NSString alloc] initWithData:data encoding:enc];
        NSRange rangeContent = [text rangeOfString:@"\""];
        if (rangeContent.location != NSNotFound && text.length>=rangeContent.location+1) {
            NSString *queryCode = [text substringWithRange:NSMakeRange(11, rangeContent.location-1 - 11)];
            NSRange rangeContentEnd = [text rangeOfString:@"\"" options:NSCaseInsensitiveSearch range:NSMakeRange(rangeContent.location+1, text.length-(rangeContent.location+1+1))];
            if (rangeContentEnd.location != NSNotFound) {
                NSString *content = [text substringWithRange:NSMakeRange(rangeContent.location+1, rangeContentEnd.location - rangeContent.location - 1)];
                
                NSArray *conArray = [content componentsSeparatedByString:@","];
                if (conArray.count > 9) {
                    [self exactData:conArray code:queryCode];
                    return;
                }
            }
        }
        printLog(@"解析出现错误 :%@",text);
    }
    
}

-(void)exactData:(NSArray *)conArray code:(NSString *)queryCode{
    
    if (self.fieldCode.stringValue.length == 0) {
        return;
    }
    if (![queryCode isEqualToString:[self getCode]]) {
        return;
    }
    
    [self cleanOldData];
    
    CODE_TYPE type = [self getCodeType];
    if(type == TYPE_Gupiao) {
        [self parseForGuPiao:conArray];
    }else if(type == TYPE_Futrue) {
        [self parseForFuture:conArray];
    }else if(type == TYPE_Foreign) {
        [self parseForForeignFuture:conArray];
    }else if(type == TYPE_MEIGU) {
        [self parseForMeiGu:conArray];
    }else if(type == TYPE_GANGGU) {
        [self parseForGangGu:conArray];
    }else {
        return;
    }
    
    
    NSDate *date = [NSDate date];
    NSString *time = [df stringFromDate:date];
    
    float percent = [dangqian floatValue] / [zuoshou floatValue] - 1;
    printLog(@"%@ 开:%@ 现:%@ 幅:%.3f 昨:%@ 高:%@ 低:%@ 成:%@ 买量:%@ 买价:%@ 卖量:%@ 卖价:%@ \ntime:%@",name,kaipan,dangqian,percent*100,zuoshou,max,min,chengjiaoe, buy1count,buy1price, sell1count, sell1price ,time);
    
    self.labelScore.stringValue = [NSString stringWithFormat:@"当前: %@",dangqian];
    self.labelPercent.stringValue = [NSString stringWithFormat:@"幅度: %.3f",percent*100];
    if(chengjiao.length > 0) {
        self.labelSubmit.stringValue = [NSString stringWithFormat:@"量: %@ w",chengjiao];
    }
    self.labelBegin.stringValue = [NSString stringWithFormat:@"开: %@",kaipan];
    self.labelCrease.stringValue = [NSString stringWithFormat:@"点: %.2f",[dangqian floatValue] - [zuoshou floatValue]];
    
    [self sendNotification:[NSString stringWithFormat:@"%.3f",percent*100] point:dangqian];
    
    if (percent>0) {
        self.labelScore.textColor = [NSColor redColor];
        self.labelPercent.textColor = [NSColor redColor];
        self.labelCrease.textColor = [NSColor redColor];
    }else{
        self.labelScore.textColor = [NSColor colorWithCalibratedRed:35/255.0 green:146/255.0 blue:83/255.0 alpha:1.0];
        self.labelPercent.textColor = [NSColor colorWithCalibratedRed:35/255.0 green:146/255.0 blue:83/255.0 alpha:1.0];
        self.labelCrease.textColor = self.labelPercent.textColor;
    }

}

- (void)cleanOldData {
    name = @"";
    kaipan = @"";
    zuoshou = @"";
    dangqian = @"";
    max = @"";
    min = @"";
    chengjiao = @"";
    chengjiaoe = @"";
    buy1count = @"";
    buy1price = @"";
    sell1count = @"";
    sell1price = @"";
}

- (void)parseForGuPiao:(NSArray *)conArray {
  
    name = conArray[0];
    kaipan = conArray[1];
    zuoshou = conArray[2];
    dangqian = conArray[3];
    max = conArray[4];
    min = conArray[5];
    chengjiao = conArray[8];
    chengjiaoe = conArray[9];
    buy1count = conArray[10];
    sell1count = conArray[20];
    buy1price = conArray[6];
    sell1price = conArray[7];
    
    chengjiao = [NSString stringWithFormat:@"%.2f",[chengjiao intValue]/100.0/10000];
    chengjiaoe = [NSString stringWithFormat:@"%.2f亿",[chengjiaoe intValue]/10000/10000.0];
    buy1count = [NSString stringWithFormat:@"%d手",[buy1count intValue]/100];
    sell1count = [NSString stringWithFormat:@"%d手",[sell1count intValue]/100];

}

- (void)parseForFuture:(NSArray *)conArray {
    
    name = conArray[0];
    kaipan = conArray[2];
    zuoshou = conArray[5];
    dangqian = conArray[8];
    max = conArray[3];
    min = conArray[4];
    chengjiao = conArray[14];
    chengjiaoe = conArray[9];
    buy1count = conArray[11];
    sell1count = conArray[12];
    buy1price = conArray[6];
    sell1price = conArray[7];

    chengjiao = [NSString stringWithFormat:@"%.2f",[chengjiao intValue]/10000.0];
    chengjiaoe = @"0";
}

- (void)parseForForeignFuture:(NSArray *)conArray {
    
    kaipan = conArray[8];
    dangqian = conArray[0];
    buy1price = conArray[2];
    sell1price = conArray[3];
    max = conArray[4];
    min = conArray[5];
    zuoshou = conArray[7];
    name = conArray[13];
}

- (void)parseForMeiGu:(NSArray *)conArray {
    
    name = conArray[0];
    kaipan = conArray[8];
    zuoshou = conArray[26];
    dangqian = conArray[1];
    max = conArray[6];
    min = conArray[7];
    chengjiao = conArray[10];
    
    
    chengjiao = [NSString stringWithFormat:@"%.2f",[chengjiao intValue]/100.0/10000];

}

- (void)parseForGangGu:(NSArray *)conArray {
    
    name = conArray[1];
    kaipan = conArray[2];
    zuoshou = conArray[3];
    dangqian = conArray[6];
    max = conArray[4];
    min = conArray[5];
    chengjiao = conArray[12];
    chengjiaoe = conArray[11];
    
    chengjiao = [NSString stringWithFormat:@"%.2f",[chengjiao intValue]/100.0/10000];
    chengjiaoe = [NSString stringWithFormat:@"%.2f亿",[chengjiaoe intValue]/10000/10000.0];
    
}

- (void)beginRequestLoop {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(update) object:nil];
    if(self.fieldTime.floatValue > 0 && self.fieldTime.floatValue < 20){
        interval = self.fieldTime.floatValue;
    }else{
        self.fieldTime.floatValue = 3;
    }
    
    if (self.fieldCode.stringValue.length > 0) {
        request.URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://hq.sinajs.cn/list=%@",[self getCode]]];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.fieldCode.stringValue forKey:@"lastCode"];
    [defaults synchronize];
    
    [self performSelector:@selector(update) withObject:nil afterDelay:interval];

}

-(void)sendNotification:(NSString *)percent point:(NSString *)point
{
    float p = [percent floatValue];
    NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:self.lastPushDate];
    
    //幅度提醒限制
    if (p > -2.0 && p < 1.0 && [self getCodeType]==TYPE_Gupiao) {
        return;
    }
    
    if (!([self.fieldCode.stringValue isEqualToString:@"000001"] || [self.fieldCode.stringValue isEqualToString:@"399001"]) && (p < -2.0 && p < 3.0)) {
        return;
    }
    
    //时间限制
    if (self.lastPushDate != nil && t < 1*60) {
        return;
    }
    
    //幅度变化百分比限制
    if ([self getCodeType] > TYPE_Gupiao) {
        if (self.lastPercent != 0 && fabs(p - self.lastPercent) < 0.2) {
            return;
        }
    }else {
        if (self.lastPercent != 0 && fabs(p - self.lastPercent) < 0.1) {
            return;
        }
    }
    
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    [notification setDeliveryDate:[NSDate date]];
    [notification setActionButtonTitle:@"测试"];
    [notification setInformativeText:[NSString stringWithFormat:@"pc:%@ pt:%@",percent,point]];
    [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
    
    self.lastPushDate = [NSDate date];
    self.lastPercent = p;

}

- (void)printLog:(NSString *)format, ...
{
    if (!format)
        return;
    
    
    @autoreleasepool {
        
        va_list arglist;
        va_start(arglist, format);
        
        NSString *outStr = [[NSString alloc] initWithFormat:format arguments:arglist] ;
        va_end(arglist);
        
        NSLog(@"%@", outStr);
        
        
        if (self.checkbox.state == 1 && outStr.length > 10) {
            
            self.logLabel.hidden = NO;
            
            NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:outStr];
            
            //时间
            [attr addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:NSMakeRange(outStr.length-13, 13)];
            
            //买量 & 卖量
            NSRange buyrange = [outStr rangeOfString:@"买量:"];
            NSRange sellrange = [outStr rangeOfString:@"卖量:"];
            if (buyrange.location != NSNotFound && sellrange.location != NSNotFound) {
                
                NSRange buyspace = [outStr rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(buyrange.location, outStr.length - buyrange.location)];
                
                NSRange sellspace = [outStr rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(sellrange.location, outStr.length - sellrange.location)];
                
                [attr addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:NSMakeRange(buyrange.location+buyrange.length, buyspace.location - (buyrange.location+buyrange.length))];
                [attr addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:NSMakeRange(sellrange.location+sellrange.length, sellspace.location - (sellrange.location+sellrange.length))];
            }
            
            self.logLabel.attributedStringValue = attr;
        }else{
            self.logLabel.hidden = YES;
            if (self.logLabel.stringValue.length > 0) {
                self.logLabel.stringValue = @"";
            }
        }
        
    }
    
}

-(NSString *)getCode
{
    NSString *code = self.fieldCode.stringValue;
    if (code.length == 0) {
        return @"";
    }

    char c = [code characterAtIndex:0];
    
    if (c >= '0' && c <= '9') {
        if (([code hasPrefix:@"0"] || [code hasPrefix:@"3"])&& ![@"000001" isEqualToString:code]) {
            return [NSString stringWithFormat:@"sz%@",code];
        }else {
            return [NSString stringWithFormat:@"sh%@",code];
        }
    }else {
        if ([code hasPrefix:@"hf_"]) {
            return [NSString stringWithFormat:@"hf_%@", [[code substringFromIndex:3] uppercaseString]];
        }else if([[code lowercaseString] hasPrefix:@"gb_"]) {
            return [code lowercaseString];
        }else if([[code lowercaseString] hasPrefix:@"hk"]) {
            return [NSString stringWithFormat:@"rt_%@", code];
        }else
            return [code uppercaseString];
    }
}

- (CODE_TYPE)getCodeType {
    
    NSString *code = self.fieldCode.stringValue;
    if (code.length == 0) {
        return TYPE_Gupiao;
    }
    
    char c = [code characterAtIndex:0];
    
    if (c >= '0' && c <= '9') {
         return TYPE_Gupiao;
    }else {
        if([code hasPrefix:@"hf_"]) {
            return TYPE_Foreign;
        }else if([code hasPrefix:@"gb_"]) {
            return TYPE_MEIGU;
        }else if([code hasPrefix:@"hk"]) {
            return TYPE_GANGGU;
        }else {
            return TYPE_Futrue;
        }
    }
}

#pragma mark - NSTextFieldDelegate

-(void)controlTextDidChange:(NSNotification *)obj
{
    if (self.fieldCode.stringValue.length >= 5) {
        [self beginRequestLoop];
    }
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

  
}

#pragma mark - 

-(void)mouseDown:(NSEvent *)theEvent
{
    [self beginRequestLoop];
}


@end
