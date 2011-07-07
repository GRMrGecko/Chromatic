//
//  MGMAdvancedPane.m
//  Chromatic
//
//  Created by Mr. Gecko on 6/10/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). http://mrgeckosmedia.com/
//
//  Permission to use, copy, modify, and/or distribute this software for any purpose
//  with or without fee is hereby granted, provided that the above copyright notice
//  and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
//  REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT,
//  OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE,
//  DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
//  ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

#import "MGMAdvancedPane.h"
#import "MGMController.h"
#import <MGMUsers/MGMUsers.h>

@implementation MGMAdvancedPane
- (id)initWithPreferences:(MGMPreferences *)thePreferences {
	if ((self = [super initWithPreferences:thePreferences])) {
        if (![NSBundle loadNibNamed:@"AdvancedPane" owner:self]) {
            NSLog(@"Unable to load Nib for Advanced Preferences");
            [self release];
            self = nil;
        } else {
			if ([preferences stringForKey:MGMCustomSnapshotURL]!=nil)
				[snapshotField setStringValue:[preferences stringForKey:MGMCustomSnapshotURL]];
			[trashButton setState:([preferences boolForKey:MGMMoveToTrash] ? NSOnState : NSOffState)];
        }
    }
    return self;
}
- (void)dealloc {
	[self save:self];
	[mainView release];
	[super dealloc];
}
+ (void)setUpToolbarItem:(NSToolbarItem *)theItem {
	[theItem setLabel:[self title]];
    [theItem setPaletteLabel:[theItem label]];
    [theItem setImage:[NSImage imageNamed:@"Advanced"]];
}
+ (NSString *)title {
	return @"Advanced";
}
- (NSView *)preferencesView {
	return mainView;
}

- (IBAction)save:(id)sender {
	[preferences setObject:[snapshotField stringValue] forKey:MGMCustomSnapshotURL];
	[preferences setBool:([trashButton state]==NSOnState) forKey:MGMMoveToTrash];
}
@end