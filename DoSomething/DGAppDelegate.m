//
//  DGAppDelegate.m
//  DoSomething
//
//  Created by Deepak Gulati on 03/01/2014.
//  Copyright (c) 2014 Deepak Gulati. All rights reserved.
//

#import "DGAppDelegate.h"

@implementation DGAppDelegate

-(id) init {
    if(self = [super init]) {
        //😀 = no tasks
        //😠 = 1-5 tasks
        //😢 = 6-10 tasks
        //😫 = 11-15 tasks
        //😵 = > 15 tasks
        icons = @[@"😀",@"😠",@"😢",@"😫",@"😵"];
        NSLog(@"%@", icons);
    }
    
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    self.reminderCount = 0;
    DGAppDelegate * __weak weakself = self;
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                    // Event creation code here.
                if(granted) {
                    weakself.theStore = eventStore;
                    NSLog(@"Got permission");
                    [weakself buildMenu];
                    [weakself subscribe];

                    
//                    NSMutableArray *searchFor = [[NSMutableArray alloc] init];
//                    EKCalendar *defaultList = [weakself.theStore defaultCalendarForNewReminders];
//                    [searchFor addObject:defaultList];
//                    
//                    NSPredicate *predicate = [weakself.theStore predicateForIncompleteRemindersWithDueDateStarting:nil ending:nil calendars:searchFor];
//                    //NSPredicate *predicate = [store predicateForRemindersInCalendars:search];
//                    [weakself.theStore fetchRemindersMatchingPredicate:predicate completion:^(NSArray *reminders) {
//                        int count = 0;
//                        NSMenu *reminderMenu = [[NSMenu alloc] init];
//                        for(EKReminder *reminder in reminders ) {
//                            
//                            //NSLog(@"%s\n", [[NSString stringWithFormat:@"%@", reminder.title] UTF8String]);
//                            NSMenuItem *item = [[NSMenuItem alloc] init];
//                            item.title = reminder.title;
//                            item.representedObject = reminder.calendarItemIdentifier;
//                            item.action = @selector(handleReminder:);
//                            item.keyEquivalent = @"";
//                            
//                            [reminderMenu addItem:item];
//                            count++;
//                        }
//                        NSStatusBar *bar = [NSStatusBar systemStatusBar];
//                        weakself.theItem = [bar statusItemWithLength:NSVariableStatusItemLength];
//                        [weakself.theItem setTitle: [NSString stringWithFormat:@"%d", count]];
//                        [weakself.theItem setHighlightMode:YES];
//                        [weakself.theItem setMenu:reminderMenu];
//                    }];
               }

            });
    }];
    
    
}

- (void) storeChanged: (NSNotificationCenter *)notificationCenter {
    //NSLog(@"%@", @"Changed!");
    //[self buildMenu];
    
    //Fire the timer that rebuilds the menu
    [self.timer fire];
}

- (void) buildMenu {

    NSLog(@"buildMenu called");
    NSMutableArray *searchFor = [[NSMutableArray alloc] init];
    EKCalendar *defaultList = [self.theStore defaultCalendarForNewReminders];
    [searchFor addObject:defaultList];
    
    NSPredicate *predicate = [self.theStore predicateForIncompleteRemindersWithDueDateStarting:nil ending:nil calendars:searchFor];
    //NSPredicate *predicate = [store predicateForRemindersInCalendars:search];
    [self.theStore fetchRemindersMatchingPredicate:predicate completion:^(NSArray *reminders) {
        int count = 0;
        int high_priority_count = 0;
        NSMenu *reminderMenu = [[NSMenu alloc] init];
        for(EKReminder *reminder in reminders ) {
            
            //NSLog(@"%s\n", [[NSString stringWithFormat:@"%@", reminder.title] UTF8String]);
            NSMenuItem *item = [[NSMenuItem alloc] init];
            item.title = reminder.title;
            item.representedObject = reminder.calendarItemIdentifier;
            item.action = @selector(handleReminder:);
            item.keyEquivalent = @"";
            
            NSMenu *subMenu = [[NSMenu alloc] init];

            NSMenuItem *edit = [[NSMenuItem alloc] init];
            edit.title = @"Edit...";
            edit.representedObject = reminder.calendarItemIdentifier;
            edit.action = @selector(edit:);
            edit.keyEquivalent = @"";
            [subMenu addItem: edit];

            
            NSMenuItem *showInReminders = [[NSMenuItem alloc] init];
            showInReminders.title = @"Show in Reminders";
            showInReminders.representedObject = reminder.calendarItemIdentifier;
            showInReminders.action = @selector(handleReminder:);
            showInReminders.keyEquivalent = @"";
            [subMenu addItem: showInReminders];
            
            
            NSMenuItem *markComplete = [[NSMenuItem alloc] init];
            markComplete.title = @"Completed";
            markComplete.representedObject = reminder.calendarItemIdentifier;
            markComplete.action = @selector(handleCompletion:);
            markComplete.keyEquivalent = @"";
            [subMenu addItem: markComplete];
            
            [item setSubmenu:subMenu];
            
            if(reminder.priority != 1) {
                [reminderMenu addItem: item];
            }
            else {
                [reminderMenu insertItem:item atIndex:0];
                high_priority_count++;
            }
            count++;
        }
        
        self.reminderCount = count;
        
        if(high_priority_count > 0) {
            [reminderMenu insertItem:[NSMenuItem separatorItem] atIndex:high_priority_count];
        }
        
        [reminderMenu addItem:[NSMenuItem separatorItem]];

        [reminderMenu addItemWithTitle:@"Add..."
                                action:@selector(add:)
                         keyEquivalent:@"a"];

        [reminderMenu addItemWithTitle:@"Refresh"
                                action:@selector(buildMenu)
                         keyEquivalent:@"r"];
         
        [reminderMenu addItemWithTitle:@"Quit"
                                action:@selector(terminate:)
                         keyEquivalent:@"q"];
        
        if (!self.theItem) {
            NSStatusBar *bar = [NSStatusBar systemStatusBar];
            self.theItem = [bar statusItemWithLength:NSVariableStatusItemLength];
            [self.theItem setAction:@selector(refreshMe:)];
            self.timer = [NSTimer scheduledTimerWithTimeInterval:30.0
                                                           target:self
                                                         selector:@selector(buildMenu)
                                                         userInfo:nil
                                                         repeats:YES];

        }
        [self.theItem setTitle: [self getTitle:count]];
        [self.theItem setToolTip:[self getTooltip:count]];
        [self.theItem setHighlightMode:YES];
        [self.theItem setMenu:reminderMenu];
    }];
    
    
}

- (void) handleReminder:(id)sender {
    NSString *calendarIdentifier = [sender representedObject];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"x-apple-reminder://%@",calendarIdentifier]];
    NSLog(@"%@", url);
    //BOOL ok = [[NSWorkspace sharedWorkspace] openURL:url];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (void) handleCompletion:(NSMenuItem *)sender {
    NSString *calendarIdentifier = [sender representedObject];
    EKReminder *reminder = (EKReminder *)[self.theStore calendarItemWithIdentifier:calendarIdentifier];
    reminder.completed = YES;
    [self.theStore saveReminder:reminder commit:YES error:nil];
    //NSLog(@"%@", reminder);
    
    [self.theItem.menu removeItem:sender.parentItem];

    self.reminderCount--;
    [self.theItem setTitle:[self getTitle:self.reminderCount]];
    [self.theItem setToolTip:[self getTooltip:self.reminderCount]];
    
    //[self.timer fire];
}

-(void) subscribe {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(storeChanged:)
                                                 name:EKEventStoreChangedNotification
                                               object:self.theStore];

}

-(void) add: (id)sender {
    self.currentReminder = @"";
    [self.window makeKeyAndOrderFront:self];
    [self.txtReminder setStringValue:@""];
    [self.window setIsVisible:YES];
}

-(void) edit: (NSMenuItem *) sender {
    self.currentReminder = sender.representedObject;
    EKReminder *reminder =
        (EKReminder *)[self.theStore calendarItemWithIdentifier:self.currentReminder];

    [self.window makeKeyAndOrderFront:self];
    [self.txtReminder setStringValue:reminder.title];
    if(reminder.priority == 1) {
        [self.chkHighPriority setState:1];
    }
    else {
        [self.chkHighPriority setState:0];
    }
    [self.window setIsVisible:YES];
    [NSApp activateIgnoringOtherApps:YES];
}

-(void) refreshMe: (id) sender {
    NSLog(@"%@", @"called");
}

- (IBAction)cancel:(id)sender {
    [self.window setIsVisible:NO];
}

- (IBAction)save:(id)sender {
    NSLog(@"%@", @"Hello World");
    EKReminder *reminder;
    if([self.currentReminder isNotEqualTo:@""]) {
        reminder = (EKReminder *)[self.theStore calendarItemWithIdentifier:self.currentReminder];
    }
    else {
        reminder = [EKReminder reminderWithEventStore:self.theStore];
        reminder.calendar = [self.theStore defaultCalendarForNewReminders];
    }
    
    if(reminder) {
        reminder.title = [self.txtReminder stringValue];
        if(self.chkHighPriority.state == 1) {
            reminder.priority = 1;
        }
        else {
            reminder.priority = 0;
        }
        [self.theStore saveReminder:reminder commit:YES error:nil];
    }
    
    self.currentReminder = @"";

    //kick a refresh of the menu.
    //[self.timer setFireDate:[[[NSDate alloc] init] dateByAddingTimeInterval:5]];
    [self.window setIsVisible:NO];

}

- (NSString *) getTooltip: (int) nCount {
    return [NSString stringWithFormat:@"%d %@", nCount, @"unfinshed tasks"];
}

- (NSString *) getTitle: (int) nCount {
    if(nCount == 0) {
        return icons[0];
    }
    else if (nCount <= 5) {
        return icons[1];
    }
    else if (nCount <= 10) {
        return icons[2];
    }
    else if (nCount <= 15) {
        return icons[3];
    }
    else {
        return icons[4];
    }
}

@end
