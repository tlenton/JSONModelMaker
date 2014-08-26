//
//  ModelMakerView.h
//  JSON Model Maker
//
//  Created by Tim Lenton on 20/03/2014.
//  Copyright (c) 2014 Westpac. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ModelMakerView : NSView

@property (strong, nonatomic) IBOutlet NSTextField *rootTextField;
@property (strong, nonatomic) IBOutlet NSTextField *rootSuperTextField;
@property (strong, nonatomic) IBOutlet NSTextField *superTextField;
@property (strong, nonatomic) IBOutlet NSTextView *jsonTextView;
@property (strong, nonatomic) IBOutlet NSTextView *headerTextView;
@property (strong, nonatomic) IBOutlet NSTextView *implementationTextView;
@property (strong, nonatomic) IBOutlet NSMatrix *radioButton;

@end
