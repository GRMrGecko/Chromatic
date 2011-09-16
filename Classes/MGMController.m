//
//  MGMController.m
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

#import "MGMController.h"
#import "MGMAddons.h"
#import <MGMUsers/MGMUsers.h>
#import <GeckoReporter/GeckoReporter.h>
#import <WebKit/WebKit.h>

NSString * const MGMCopyright = @"Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/";
NSString * const MGMVersion = @"MGMVersion";
NSString * const MGMLaunchCount = @"MGMLaunchCount";

NSString * const MGMChannel = @"MGMChannel";
NSString * const MGMChromiumPath = @"MGMChromiumPath";
NSString * const MGMCustomSnapshotURL = @"MGMCustomSnapshotURL";
NSString * const MGMMoveToTrash = @"MGMMoveToTrash";
NSString * const MGMDoneSound = @"MGMDoneSound";
NSString * const MGMLaunchWhenDone = @"MGMLaunchWhenDone";
NSString * const MGMQuitAfterLaunch = @"MGMQuitAfterLaunch";

NSString * const MGMCPApplications = @"/Applications";
NSString * const MGMCPUserApplications = @"~/Applications";
NSString * const MGMCPChromium = @"Chromium.app";
NSString * const MGMCPRevision = @"SVNRevision";
NSString * const MGMChromiumZip = @"chrome-mac.zip";
NSString * const MGMTMPPath = @"/tmp";

NSString * const MGMChannelsURL = @"http://omahaproxy.appspot.com/all.json?os=mac";
static NSString *MGMSnapshotURL = @"https://commondatastorage.googleapis.com/chromium-browser-snapshots/";
NSString * const MGMSnapshotPrefix = @"Mac/";
NSString * const MGMSVNLogsURL = @"http://build.chromium.org/f/chromium/perf/dashboard/ui/changelog.html?url=/trunk/src&range=%@:%@&mode=html&os=mac";

NSString * const MGMCChannel = @"channel";
NSString * const MGMCRevision = @"base_trunk_revision";
NSString * const MGMCStable = @"stable";
NSString * const MGMCBeta = @"beta";
NSString * const MGMCDev = @"dev";
NSString * const MGMCCanary = @"canary";

NSString * const MGMUBUpdate = @"Update";
NSString * const MGMUBInstall = @"Install";
NSString * const MGMUBCancel = @"Cancel";

@interface NSString (MGMAddonsSort)
- (NSComparisonResult)numberCompare:(id)theItem;
@end


@implementation NSString (MGMAddonsSort)
- (NSComparisonResult)numberCompare:(id)theItem {
	unsigned int theNumber = 0;
	unsigned int number = 0;
	if ([theItem isKindOfClass:[NSString class]])
		sscanf([theItem UTF8String], "%u", &theNumber);
	sscanf([self UTF8String], "%u", &number);
	if (number<theNumber)
		return NSOrderedAscending;
	else if (number>theNumber)
		return NSOrderedDescending;
	return NSOrderedSame;
}
@end


@interface NSOpenPanel (MGMIgnore)
- (void)setDirectoryURL:(NSURL *)url;
- (void)setDirectory:(NSString *)path;
@end

@implementation MGMController
- (void)awakeFromNib {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setup) name:MGMGRDoneNotification object:nil];
	[MGMReporter sharedReporter];
}
- (void)setup {
	connectionManager = [[MGMURLConnectionManager manager] retain];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:MGMVersion]==nil) {
		NSString *oldPathKey = @"cPathKey";
		[defaults setObject:[defaults stringForKey:oldPathKey] forKey:MGMChromiumPath];
		[defaults removeObjectForKey:oldPathKey];
		
		[defaults setObject:[[MGMSystemInfo info] applicationVersion] forKey:MGMVersion];
	}
	[self registerDefaults];
	if ([defaults integerForKey:MGMLaunchCount]!=5) {
		[defaults setInteger:[defaults integerForKey:MGMLaunchCount]+1 forKey:MGMLaunchCount];
		if ([defaults integerForKey:MGMLaunchCount]==5) {
			NSAlert *alert = [[NSAlert new] autorelease];
			[alert setMessageText:@"Donations"];
			[alert setInformativeText:@"Thank you for using Chromatic. Chromatic is donation supported software. If you like using it, please consider giving a donation to help with development."];
			[alert addButtonWithTitle:@"Yes"];
			[alert addButtonWithTitle:@"No"];
			int result = [alert runModal];
			if (result==1000)
				[self donate:self];
		}
	}
	
	if ([defaults objectForKey:MGMCustomSnapshotURL]!=nil && ![[defaults objectForKey:MGMCustomSnapshotURL] isEqual:@""])
		MGMSnapshotURL = [defaults objectForKey:MGMCustomSnapshotURL];
	
	about = [MGMAbout new];
	preferences = [MGMPreferences new];
	[preferences addPreferencesPaneClassName:@"MGMGeneralPane"];
	[preferences addPreferencesPaneClassName:@"MGMAdvancedPane"];
	
	startingUp = YES;
	[mainWindow makeKeyAndOrderFront:self];
	[progress startAnimation:self];
	[updateButton setEnabled:NO];
	
	[channelPopUp selectItemAtIndex:[defaults integerForKey:MGMChannel]];
	
	channelRevisions = [NSMutableDictionary new];
	
	NSString *path = [defaults objectForKey:MGMChromiumPath];
	if (path==nil)
		path = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"Chromium"];
	if (path==nil) {
		NSFileManager *manager = [NSFileManager defaultManager];
		if ([manager isWritableFileAtPath:MGMCPApplications]) {
			path = [MGMCPApplications stringByAppendingPathComponent:MGMCPChromium];
		} else {
			if ([manager fileExistsAtPath:[MGMCPUserApplications stringByExpandingTildeInPath]])
				[manager createDirectoryAtPath:[MGMCPUserApplications stringByExpandingTildeInPath] withAttributes:nil];
			path = [[MGMCPUserApplications stringByExpandingTildeInPath] stringByAppendingPathComponent:MGMCPChromium];
		}
	}
	chromiumPath = [path copy];
	
	[self updateChromiumPath];
	
	MGMURLBasicHandler *handler = [MGMURLBasicHandler handlerWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:MGMChannelsURL]] delegate:self]; 
	[handler setFailWithError:@selector(channels:didFailWithError:)];
	[handler setFinish:@selector(channelsFinished:)];
	[connectionManager addHandler:handler];
	revisionsArray = [NSMutableArray new];
	NSString *url = [MGMSnapshotURL stringByAppendingFormat:@"?delimiter=/&prefix=%@", MGMSnapshotPrefix];
	handler = [MGMURLBasicHandler handlerWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]] delegate:self];
	[handler setFailWithError:@selector(revisions:didFailWithError:)];
	[handler setFinish:@selector(revisionsFinished:)];
	[connectionManager addHandler:handler];
}

- (void)registerDefaults {
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	[defaults setObject:[NSNumber numberWithInt:1] forKey:MGMLaunchCount];
	[defaults setObject:[NSNumber numberWithInt:4] forKey:MGMChannel];
	[defaults setObject:[NSNumber numberWithBool:YES] forKey:MGMMoveToTrash];
	[defaults setObject:[NSNumber numberWithBool:YES] forKey:MGMDoneSound];
	[defaults setObject:[NSNumber numberWithBool:NO] forKey:MGMLaunchWhenDone];
	[defaults setObject:[NSNumber numberWithBool:NO] forKey:MGMQuitAfterLaunch];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (IBAction)about:(id)sender {
	[about show];
}
- (IBAction)preferences:(id)sender {
	[preferences showPreferences];
}
- (IBAction)donate:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=9184741"]];
}
- (IBAction)openSource:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://opensource.mrgeckosmedia.com/Chromatic?application"]];
}

- (void)channels:(MGMURLBasicHandler *)theHandler didFailWithError:(NSError *)theError {
	NSLog(@"%@", theError);
	NSAlert *alert = [[NSAlert new] autorelease];
	[alert setMessageText:@"Error loading channel info"];
	[alert setInformativeText:[theError localizedDescription]];
	[alert runModal];
}
- (void)channelsFinished:(MGMURLBasicHandler *)theHandler {
	NSArray *versions = [[[[theHandler data] parseJSON] objectAtIndex:0] objectForKey:@"versions"];
	if (versions==nil) {
		NSAlert *alert = [[NSAlert new] autorelease];
		[alert setMessageText:@"Error loading channel info"];
		[alert setInformativeText:@"The JSON was unable to be parsed."];
		[alert runModal];
	}
	for (int i=0; i<[versions count]; i++) {
		NSDictionary *versionInfo = [versions objectAtIndex:i];
		[channelRevisions setObject:[[versionInfo objectForKey:MGMCRevision] stringValue] forKey:[versionInfo objectForKey:MGMCChannel]];
	}
	
	[progress setIndeterminate:NO];
	[progress startAnimation:self];
	[progress setDoubleValue:0.25];
}
- (void)revisions:(MGMURLBasicHandler *)theHandler didFailWithError:(NSError *)theError {
	NSLog(@"%@", theError);
	NSAlert *alert = [[NSAlert new] autorelease];
	[alert setMessageText:@"Error loading revisions"];
	[alert setInformativeText:[theError localizedDescription]];
	[alert runModal];
	NSMenu *items = [NSMenu new];
	[revisionsArray sortUsingSelector:@selector(numberCompare:)];
	for (unsigned int i=0; i<[revisionsArray count]; i++) {
		NSMenuItem *item = [NSMenuItem new];
		[item setTitle:[revisionsArray objectAtIndex:i]];
		[items addItem:item];
		[item release];
	}
	[buildPopUp removeAllItems];
	[buildPopUp setMenu:items];
	[items release];
	[revisionsArray release];
	revisionsArray = nil;
	[self channelSelect:self];
}
- (void)revisionsFinished:(MGMURLBasicHandler *)theHandler {
	NSError *error = nil;
	NSXMLDocument *xml = [[NSXMLDocument alloc] initWithData:[theHandler data] options:NSXMLDocumentTidyXML error:&error];
	[progress setDoubleValue:0.50];
	
	if (error!=nil) {
		NSLog(@"%@", error);
		NSAlert *alert = [[NSAlert new] autorelease];
		[alert setMessageText:@"Error parsing revisions"];
		[alert setInformativeText:[error localizedDescription]];
		[alert runModal];
		NSMenu *items = [NSMenu new];
		[revisionsArray sortUsingSelector:@selector(numberCompare:)];
		for (unsigned int i=0; i<[revisionsArray count]; i++) {
			NSMenuItem *item = [NSMenuItem new];
			[item setTitle:[revisionsArray objectAtIndex:i]];
			[items addItem:item];
			[item release];
		}
		[buildPopUp removeAllItems];
		[buildPopUp setMenu:items];
		[items release];
		[revisionsArray release];
		revisionsArray = nil;
		[self channelSelect:self];
	} else {
		NSXMLElement *rootElement = [xml rootElement];
		NSArray *isTruncated = [rootElement elementsForName:@"IsTruncated"];
		NSArray *commonPrefixes = [rootElement elementsForName:@"CommonPrefixes"];
		for (int i=0; i<[commonPrefixes count]; i++) {
			NSArray *prefix = [[commonPrefixes objectAtIndex:i] elementsForName:@"Prefix"];
			if ([prefix count]<1)
				continue;
			NSArray *parsed = [[[prefix objectAtIndex:0] stringValue] componentsSeparatedByString:@"/"];
			if ([parsed count]<2)
				continue;
			[revisionsArray addObject:[parsed objectAtIndex:1]];
		}
		NSArray *nextMarkers = [rootElement elementsForName:@"NextMarker"];
		if ([isTruncated count]>0 && [[[isTruncated objectAtIndex:0] stringValue] isEqual:@"true"] && [nextMarkers count]>0) {
			NSString *nextMarker = [[nextMarkers objectAtIndex:0] stringValue];
			NSString *url = [MGMSnapshotURL stringByAppendingFormat:@"?delimiter=/&prefix=%@&marker=%@", MGMSnapshotPrefix, nextMarker];
			MGMURLBasicHandler *handler = [MGMURLBasicHandler handlerWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]] delegate:self];
			[handler setFailWithError:@selector(revisions:didFailWithError:)];
			[handler setFinish:@selector(revisionsFinished:)];
			[connectionManager addHandler:handler];
		} else {
			NSMenu *items = [NSMenu new];
			[revisionsArray sortUsingSelector:@selector(numberCompare:)];
			for (unsigned int i=0; i<[revisionsArray count]; i++) {
				NSMenuItem *item = [NSMenuItem new];
				[item setTitle:[revisionsArray objectAtIndex:i]];
				[items addItem:item];
				[item release];
			}
			[buildPopUp removeAllItems];
			[buildPopUp setMenu:items];
			[items release];
			[revisionsArray release];
			revisionsArray = nil;
			[self channelSelect:self];
		}
	}
	[xml release];
}

- (IBAction)channelSelect:(id)sender {
	[[NSUserDefaults standardUserDefaults] setInteger:[channelPopUp indexOfSelectedItem] forKey:MGMChannel];
	NSArray *revisions = [buildPopUp itemTitles];
	NSString *revision = nil;
	if ([channelPopUp indexOfSelectedItem]==0)
		revision = [channelRevisions objectForKey:MGMCStable];
	else if ([channelPopUp indexOfSelectedItem]==1)
		revision = [channelRevisions objectForKey:MGMCBeta];
	else if ([channelPopUp indexOfSelectedItem]==2)
		revision = [channelRevisions objectForKey:MGMCDev];
	else if ([channelPopUp indexOfSelectedItem]==3)
		revision = [channelRevisions objectForKey:MGMCCanary];
	if (revision==nil)
		revision = [revisions lastObject];
	long itemIndex = [revisions indexOfObject:revision];
	if (itemIndex==NSNotFound) {
		[buildWarningField setHidden:NO];
		for (unsigned int i=0; i<[revisions count]; i++) {
			if ([(NSString *)[revisions objectAtIndex:i] numberCompare:revision]==NSOrderedDescending) {
				itemIndex = i;
				break;
			}
		}
		if (itemIndex==NSNotFound)
			itemIndex = [revisions count]-1;
	} else {
		[buildWarningField setHidden:YES];
	}
	[buildPopUp selectItemAtIndex:itemIndex];
	if (startingUp)
		[progress setDoubleValue:0.75];
	[self buildSelect:self];
}
- (IBAction)buildSelect:(id)sender {
	NSURL *buildURL = [[[[NSURL URLWithString:MGMSnapshotURL] appendPathComponent:MGMSnapshotPrefix] appendPathComponent:[buildPopUp titleOfSelectedItem]] appendPathComponent:@"REVISIONS"];
	MGMURLBasicHandler *handler = [MGMURLBasicHandler handlerWithRequest:[NSURLRequest requestWithURL:buildURL] delegate:self];
	[handler setFailWithError:@selector(revision:didFailWithError:)];
	[handler setReceiveResponse:@selector(revision:didReceiveResponse:)];
	[handler setFinish:@selector(revisionDidFinish:)];
	[connectionManager addHandler:handler];
	
	if (![[yourBuildField stringValue] isEqual:@""] && [buildPopUp indexOfSelectedItem]!=-1 && ![[yourBuildField stringValue] isEqual:[buildPopUp titleOfSelectedItem]])
		[svnLogsButton setEnabled:YES];
	else
		[svnLogsButton setEnabled:NO];
}

- (void)revision:(MGMURLBasicHandler *)theHandler didFailWithError:(NSError *)theError {
	NSLog(@"%@", theError);
	NSAlert *alert = [[NSAlert new] autorelease];
	[alert setMessageText:@"Error loading revision info"];
	[alert setInformativeText:[theError localizedDescription]];
	[alert runModal];
	if (startingUp) {
		[progress setDoubleValue:1.0];
		[progress setIndeterminate:YES];
		[progress setDoubleValue:0.0];
		[progress stopAnimation:self];
		
		[updateButton setEnabled:YES];
		startingUp = NO;
	}
}
- (void)revision:(MGMURLBasicHandler *)theHandler didReceiveResponse:(NSHTTPURLResponse *)theResponse {
	NSString *modified = [[theResponse allHeaderFields] objectForKey:@"Last-Modified"];
	NSDateFormatter *formatter = [NSDateFormatter new];
	[formatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease]];
	[formatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
	NSDate *date = [formatter dateFromString:modified];
	[formatter release];
	formatter = [NSDateFormatter new];
	[formatter setDateFormat:@"MMMM d, yyyy hh:mm:ss a"];
	NSString *dateString = [formatter stringFromDate:date];
	[formatter release];
	if (dateString!=nil)
		[buildDateField setStringValue:dateString];
	else
		[buildDateField setStringValue:@"N/A"];
}
- (void)revisionDidFinish:(MGMURLBasicHandler *)theHandler {
	NSDictionary *revisionInfo = [[theHandler data] parseJSON];
	NSString *webkit = [[revisionInfo objectForKey:@"webkit_revision"] stringValue];
	if (webkit!=nil)
		[webKitBuildField setStringValue:webkit];
	else
		[webKitBuildField setStringValue:@"0"];
	NSString *v8 = [[revisionInfo objectForKey:@"v8_revision"] stringValue];
	if (v8!=nil)
		[v8BuildField setStringValue:v8];
	else
		[v8BuildField setStringValue:@"0"];
	if (startingUp) {
		[progress setDoubleValue:1.0];
		[progress setIndeterminate:YES];
		[progress setDoubleValue:0.0];
		[progress stopAnimation:self];
		
		[updateButton setEnabled:YES];
		startingUp = NO;
	}
}

- (IBAction)choosePath:(id)sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	if ([openPanel respondsToSelector:@selector(setDirectory:)])
		[openPanel setDirectory:[chromiumPath stringByDeletingLastPathComponent]];
	else
		[openPanel setDirectoryURL:[NSURL fileURLWithPath:[chromiumPath stringByDeletingLastPathComponent]]];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setTitle:@"Choose path for Chromium"];
	[openPanel setPrompt:@"Choose"];
	int result = [openPanel runModal];
	if (result==NSOKButton) {
		NSString *newPath = [[[openPanel URLs] objectAtIndex:0] path];
		NSFileManager *manager = [NSFileManager defaultManager];
		if ([manager isWritableFileAtPath:newPath]) {
			[chromiumPath release];
			chromiumPath = [[newPath stringByAppendingPathComponent:MGMCPChromium] retain];
			[[NSUserDefaults standardUserDefaults] setObject:chromiumPath forKey:MGMChromiumPath];
			[self updateChromiumPath];
		} else {
			NSAlert *alert = [[NSAlert new] autorelease];
			[alert setInformativeText:@"Not Writable"];
			[alert setMessageText:@"The directory you choose is not writable. To beable to use it with Chromatic, you need to change permissions."];
			[alert runModal];
		}
	}
}
- (void)updateChromiumPath {
	NSFileManager *manager = [NSFileManager defaultManager];
	if ([manager fileExistsAtPath:chromiumPath]) {
		NSDictionary *chromiumInfo = (NSDictionary *)CFBundleCopyInfoDictionaryInDirectory((CFURLRef)[NSURL fileURLWithPath:chromiumPath]);
		[yourBuildField setStringValue:[chromiumInfo objectForKey:MGMCPRevision]];
		[chromiumInfo release];
		
		NSDictionary *chromeAttributes = [manager attributesOfItemAtPath:chromiumPath];
		NSDate *date = [chromeAttributes objectForKey:NSFileModificationDate];
		NSDateFormatter *formatter = [[NSDateFormatter new] autorelease];
		[formatter setDateFormat:@"MMMM d, yyyy hh:mm:ss a"];
		[installDateField setStringValue:[formatter stringFromDate:date]];
		[launchButton setEnabled:YES];
		[updateButton setTitle:MGMUBUpdate];
		if (![[yourBuildField stringValue] isEqual:@""] && [buildPopUp indexOfSelectedItem]!=-1 && ![[yourBuildField stringValue] isEqual:[buildPopUp titleOfSelectedItem]])
			[svnLogsButton setEnabled:YES];
		else
			[svnLogsButton setEnabled:NO];
	} else {
		[launchButton setEnabled:NO];
		[svnLogsButton setEnabled:NO];
		[yourBuildField setStringValue:@""];
		[installDateField setStringValue:@""];
		[updateButton setTitle:MGMUBInstall];
	}
	
	[pathField setStringValue:[chromiumPath stringByDeletingLastPathComponent]];
}

- (IBAction)launchChromium:(id)sender {
	[[NSWorkspace sharedWorkspace] launchApplication:chromiumPath];
	if ([[NSUserDefaults standardUserDefaults] boolForKey:MGMQuitAfterLaunch])
		[[NSApplication sharedApplication] terminate:self];
}
- (IBAction)viewSVNLogs:(id)sender {
	NSString *revision1, *revision2, *tmp;
	revision1 = [yourBuildField stringValue];
	revision2 = [buildPopUp titleOfSelectedItem];
	if ([revision1 numberCompare:revision2]==NSOrderedDescending) {
		tmp = revision1;
		revision1 = revision2;
		revision2 = tmp;
	}
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:MGMSVNLogsURL, revision1, revision2]];
	
	[[svnLogsBrowser mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
	[svnLogsWindow makeKeyAndOrderFront:self];
}
- (IBAction)update:(id)sender {
	if ([[updateButton title] isEqual:MGMUBCancel]) {
		[connectionManager cancelHandler:updateHandler];
		[updateHandler release];
		updateHandler = nil;
		[[NSFileManager defaultManager] removeItemAtPath:[MGMTMPPath stringByAppendingPathComponent:MGMChromiumZip]];
		[self updateDone];
	} else {
		[progress startAnimation:self];
		startTime = [[NSDate date] timeIntervalSince1970];
		
		NSURL *url = [[[[NSURL URLWithString:MGMSnapshotURL] appendPathComponent:MGMSnapshotPrefix] appendPathComponent:[buildPopUp titleOfSelectedItem]] appendPathComponent:MGMChromiumZip];
		[updateHandler release];
		updateHandler = [[MGMURLBasicHandler handlerWithRequest:[NSURLRequest requestWithURL:url] delegate:self] retain];
		[updateHandler setFile:[MGMTMPPath stringByAppendingPathComponent:MGMChromiumZip]];
		[updateHandler setFailWithError:@selector(update:didFailWithError:)];
		[updateHandler setReceiveResponse:@selector(update:didReceiveResponse:)];
		[updateHandler setBytesReceived:@selector(update:receivedBytes:totalBytes:expectedBytes:)];
		[updateHandler setFinish:@selector(updateDidFinish:)];
		[updateHandler setSynchronous:NO];
		[connectionManager addHandler:updateHandler];
		
		[channelPopUp setEnabled:NO];
		[buildPopUp setEnabled:NO];
		[updateButton setTitle:MGMUBCancel];
	}
}

- (void)windowWillClose:(NSNotification *)notification {
	[[svnLogsBrowser mainFrame] loadHTMLString:@"" baseURL:nil];
}

- (void)update:(MGMURLBasicHandler *)theHandler didFailWithError:(NSError *)theError {
	NSLog(@"%@", theError);
	NSAlert *alert = [[NSAlert new] autorelease];
	[alert setMessageText:@"Error downloading update"];
	[alert setInformativeText:[theError localizedDescription]];
	[alert runModal];
}
- (void)update:(MGMURLBasicHandler *)theHandler didReceiveResponse:(NSHTTPURLResponse *)theResponse {
	[progress setIndeterminate:NO];
	[progress startAnimation:self];
	bytesReceivedArray = [NSMutableArray new];
}
- (void)update:(MGMURLBasicHandler *)theHandler receivedBytes:(unsigned long)theBytes totalBytes:(unsigned long)theTotalBytes expectedBytes:(unsigned long)theExpectedBytes {
	bytesReceived += theBytes;
	if (lastCheck==nil || [lastCheck timeIntervalSinceNow]<-1.0) {
		[lastCheck release];
		lastCheck = [NSDate new];
		
		while ([bytesReceivedArray count]>15) {
			[bytesReceivedArray removeObjectAtIndex:0];
		}
		[bytesReceivedArray addObject:[NSNumber numberWithUnsignedLong:bytesReceived]];
		
		averageBytesReceived = 0;
		for (int i=0; i<[bytesReceivedArray count]; i++) {
			averageBytesReceived += [[bytesReceivedArray objectAtIndex:i] unsignedLongValue];
		}
		averageBytesReceived /= [bytesReceivedArray count];
		
		[statusField setStringValue:[NSString stringWithFormat:@"%@ of %@ (%@/sec) - %@", [NSString readableMemory:theTotalBytes], [NSString readableMemory:theExpectedBytes], [NSString readableMemory:bytesReceived], [NSString readableTime:(theExpectedBytes-theTotalBytes)/averageBytesReceived]]];
		
		bytesReceived = 0;
	}
	[progress setDoubleValue:(double)theTotalBytes/(double)theExpectedBytes];
	totalBytes = theTotalBytes;
}
- (void)updateDidFinish:(MGMURLBasicHandler *)theHandler {
	[updateHandler release];
	updateHandler = nil;
	[bytesReceivedArray release];
	bytesReceivedArray = nil;
	
	[updateButton setEnabled:NO];
	[progress setIndeterminate:YES];
	[progress startAnimation:self];
	[statusField setStringValue:@"Uncompressing and installing update."];
	
	unzipTask = [NSTask new];
	[unzipTask setLaunchPath:@"/usr/bin/ditto"];
	[unzipTask setArguments:[NSArray arrayWithObjects:@"-v", @"-x", @"-k", @"--rsrc", [MGMTMPPath stringByAppendingPathComponent:MGMChromiumZip], MGMTMPPath, nil]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUnzipped:) name:NSTaskDidTerminateNotification object:unzipTask];
	[unzipTask launch];
}

- (void)updateUnzipped:(NSNotification *)theNotification {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSFileManager *manager = [NSFileManager defaultManager];
	
	if ([manager fileExistsAtPath:chromiumPath]) {
		if ([defaults boolForKey:MGMMoveToTrash]) {
			NSString *trash = [@"~/.Trash" stringByExpandingTildeInPath];
			NSInteger tag;
			[[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:[chromiumPath stringByDeletingLastPathComponent] destination:trash files:[NSArray arrayWithObject:[chromiumPath lastPathComponent]] tag:&tag];
			if (tag!=0)
				NSLog(@"Error Deleting: %ld", (long)tag);
		} else {
			[manager removeItemAtPath:chromiumPath];
		}
	}
	
	NSString *extractedPath = [[MGMTMPPath stringByAppendingPathComponent:[MGMChromiumZip stringByDeletingPathExtension]] stringByAppendingPathComponent:MGMCPChromium];
	if (![manager moveItemAtPath:extractedPath toPath:chromiumPath]) {
		NSBeep();
		[self updateDone];
		[statusField setStringValue:[NSString stringWithFormat:@"Unable to %@ due to an error. This may be a permissions issue.", [[updateButton title] lowercaseString]]];
		return;
	}
	
	[manager removeItemAtPath:[extractedPath stringByDeletingLastPathComponent]];
	[manager removeItemAtPath:[MGMTMPPath stringByAppendingPathComponent:MGMChromiumZip]];
	[manager setAttributes:[NSDictionary dictionaryWithObject:[NSDate date] forKey:NSFileModificationDate] ofItemAtPath:chromiumPath];
	
	[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
	
	[self updateDone];
	
	int time = [[NSDate date] timeIntervalSince1970]-startTime;
	[statusField setStringValue:[NSString stringWithFormat:@"%@ downloaded at %@/sec in %@", [NSString readableMemory:totalBytes], [NSString readableMemory:averageBytesReceived], [NSString readableTime:time]]];
	
	if ([defaults boolForKey:MGMDoneSound]) {
		NSSound *done = [NSSound soundNamed:@"Glass"];
		[done setDelegate:self];
		[done play];
	}
	
	[updateButton setEnabled:YES];
	
	if ([defaults boolForKey:MGMLaunchWhenDone] && [defaults boolForKey:MGMDoneSound] && ![defaults boolForKey:MGMQuitAfterLaunch])
		[self launchChromium:self];
}
- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)didFinish {
	if (didFinish) {
		[sound release];
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		if ([defaults boolForKey:MGMLaunchWhenDone] && [defaults boolForKey:MGMQuitAfterLaunch])
			[self launchChromium:self];
	}
}

- (void)updateDone {
	[self updateChromiumPath];
	[channelPopUp setEnabled:YES];
	[buildPopUp setEnabled:YES];
	[progress setIndeterminate:YES];
	[progress setDoubleValue:0.0];
	[progress stopAnimation:self];
	[statusField setStringValue:@""];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	if (updateHandler!=nil)
		[self update:self];
}
@end