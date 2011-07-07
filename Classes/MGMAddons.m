//
//  MGMAddons.m
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

#import "MGMAddons.h"

@implementation NSString (MGMAddons)
+ (NSString *)readableMemory:(unsigned long)theBytes {
	double bytes = theBytes;
	NSString *types[] = {@"Bytes", @"KB", @"MB", @"GB", @"TB", @"PB", @"EB", @"ZB", @"YB", @"BB"};
	int type = 0;
	while (bytes>1024 && type<=9) {
		bytes /= 1024;
		type++;
	}
	return [NSString stringWithFormat:@"%.02f %@", bytes, types[type]];
}
+ (NSString *)readableTime:(unsigned long)theSeconds {
	unsigned long time = theSeconds;
	int seconds = time%60;
	time = time/60;
	int minutes = time%60;
	time = time/60;
	int hours = time%24;
	unsigned long days = time/24;
	NSString *string;
	if (days!=0) {
		string = [NSString stringWithFormat:@"%lu day%@ %02d:%02d:%02d", days, (days==1 ? @"" : @"s"), hours, minutes, seconds];
	} else if (hours!=0) {
		string = [NSString stringWithFormat:@"%d:%02d:%02d", hours, minutes, seconds];
	} else {
		string = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
	}
	return string;
}
@end


@implementation NSURL (MGMAddons)
- (NSURL *)appendPathComponent:(NSString *)theComponent {
	NSMutableString *string = [NSMutableString string];
	if ([self scheme]!=nil)
		[string appendFormat:@"%@://", [self scheme]];
	if ([self host]!=nil)
		[string appendString:[self host]];
	if ([self port]!=0)
		[string appendFormat:@":%d", [self port]];
	if ([self path]!=nil) {
		if (theComponent!=nil) {
			[string appendString:[[self path] stringByAppendingPathComponent:theComponent]];
			if ([theComponent isEqual:@""] || [theComponent hasSuffix:@"/"])
				[string appendString:@"/"];
		} else {
			[string appendString:[self path]];
			if ([[self absoluteString] hasSuffix:@"/"])
				[string appendString:@"/"];
		}
	} else {
		[string appendString:[@"/" stringByAppendingPathComponent:theComponent]];
	}
	if ([self query]!=nil)
		[string appendFormat:@"?%@", [self query]];
	return [NSURL URLWithString:string];
}
@end