//
//  DGAppDelegate.h
//  DoSomething
//
//  Created by Deepak Gulati on 03/01/2014.
//  Copyright (c) 2014 Deepak Gulati. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <EventKit/EventKit.h>

@interface DGAppDelegate : NSObject <NSApplicationDelegate>
{
    @private NSArray *icons;
}

@property (assign) IBOutlet NSWindow *window;
@property (strong) NSStatusItem *theItem;
@property (strong) EKEventStore *theStore;
@property (strong) NSMenu *theMenu;
@property int reminderCount;
@property (strong) NSString *currentReminder;
@property (weak) NSTimer *timer;
@property (weak) IBOutlet NSButton *btnSave;
@property (weak) IBOutlet NSButton *btnCancel;
@property (weak) IBOutlet NSTextField *txtReminder;
@property (weak) IBOutlet NSButton *chkHighPriority;

- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;
- (void)handleReminder:(id)sender;

@end
