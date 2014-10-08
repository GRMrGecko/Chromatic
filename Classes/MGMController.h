//
//  MGMController.h
//  Chromatic
//
//  Created by Mr. Gecko on 6/9/11.
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

#import <Cocoa/Cocoa.h>

@class MGMAbout, MGMPreferences, MGMURLConnectionManager, MGMURLBasicHandler, WebView;

extern NSString * const MGMCustomSnapshotURL;
extern NSString * const MGMCustomSnapshotPrefix;
extern NSString * const MGMMoveToTrash;
extern NSString * const MGMDoneSound;
extern NSString * const MGMLaunchWhenDone;
extern NSString * const MGMQuitAfterLaunch;
extern NSString * const MGM64bit;

@interface MGMController : NSObject
#if (MAC_OS_X_VERSION_MAX_ALLOWED >= 1060)
<NSApplicationDelegate>
#endif
{
	IBOutlet NSWindow *mainWindow;
	
	MGMAbout *about;
	MGMPreferences *preferences;
	
	MGMURLConnectionManager *connectionManager;
	BOOL startingUp;
	
	NSMutableDictionary *channelRevisions;
	NSString *chromiumPath;
	
	NSMutableArray *revisionsArray;
	
	IBOutlet NSPopUpButton *channelPopUp;
	IBOutlet NSTextField *buildWarningField;
	IBOutlet NSPopUpButton *buildPopUp;
	IBOutlet NSTextField *webKitBuildField;
	IBOutlet NSTextField *v8BuildField;
	IBOutlet NSTextField *buildDateField;
	IBOutlet NSTextField *yourBuildField;
	IBOutlet NSTextField *installDateField;
	IBOutlet NSTextField *pathField;
	
	IBOutlet NSProgressIndicator *progress;
	IBOutlet NSTextField *statusField;
	
	IBOutlet NSButton *launchButton;
	IBOutlet NSButton *svnLogsButton;
	IBOutlet NSButton *updateButton;
	
	IBOutlet NSWindow *svnLogsWindow;
	IBOutlet WebView *svnLogsBrowser;
	
	int startTime;
	MGMURLBasicHandler *updateHandler;
	NSDate *lastCheck;
	unsigned long bytesReceived;
	unsigned long averageBytesReceived;
	unsigned long totalBytes;
	NSMutableArray *bytesReceivedArray;
	
	NSTask *unzipTask;
}
- (void)registerDefaults;

- (IBAction)about:(id)sender;
- (IBAction)preferences:(id)sender;
- (IBAction)donate:(id)sender;
- (IBAction)openSource:(id)sender;

- (IBAction)channelSelect:(id)sender;
- (IBAction)buildSelect:(id)sender;
- (IBAction)choosePath:(id)sender;
- (void)updateChromiumPath;

- (IBAction)launchChromium:(id)sender;
- (IBAction)viewSVNLogs:(id)sender;
- (IBAction)update:(id)sender;

- (void)updateDone;
@end