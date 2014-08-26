//
//  AppDelegate.h
//  JSON Model Maker
//
//  Created by Tim Lenton on 20/03/2014.
//  Copyright (c) 2014 Westpac. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JSONModelMaker.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (strong, nonatomic) JSONModelMaker *jsonModelMaker;

@end
