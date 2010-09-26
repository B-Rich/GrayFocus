//
//  Grayifier.m
//  GrayFocus
//
//  Created by Andy Matuschak on 8/5/10.
//  Copyright 2010 Andy Matuschak. All rights reserved.
//

#import "Grayifier.h"
#include <Carbon/Carbon.h>
#import "CGSPrivate.h"

extern OSStatus CGSNewConnection(const void **attributes, CGSConnection * id);

@implementation Grayifier

static CGSWindowFilterRef grayscaleFilter;
static CGSConnection connection;
static NSMutableDictionary *oldWindowValues = nil;
static double unfocusedAlphaValue = 0.6;
static double focusedAlphaValue = 1;

+ (void)load
{
	oldWindowValues = [[NSMutableDictionary dictionary] retain];
	
	CGSNewConnection(NULL, &connection);
	CGSNewCIFilterByName(connection, (CFStringRef)@"CIColorControls", &grayscaleFilter);
	CGSSetCIFilterValuesFromDictionary(connection, grayscaleFilter, (CFDictionaryRef)[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0] forKey:@"inputSaturation"]);
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(grayify:) name:NSWindowDidResignKeyNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(grayify:) name:NSWindowDidResignMainNotification object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorize:) name:NSWindowDidBecomeMainNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(colorize:) name:NSWindowDidBecomeKeyNotification object:nil];
}

+ (void)grayify:(NSNotification *)note
{	
	NSWindow *window = (NSWindow *)[note object];
	CGSAddWindowFilter(connection, [window windowNumber], grayscaleFilter, 1 << 2);
	
	NSDictionary *oldValues = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:[window isOpaque]], @"opaque",
																		 [NSNumber numberWithDouble:[window alphaValue]], @"alphaValue", nil];
	[oldWindowValues setObject:oldValues forKey:[NSValue valueWithPointer:window]];
	
	[window setOpaque:NO];
	[window setAlphaValue:unfocusedAlphaValue];
}

+ (void)colorize:(NSNotification *)note
{
	NSWindow *window = (NSWindow *)[note object];
	CGSRemoveWindowFilter(connection, [window windowNumber], grayscaleFilter);

	[window setOpaque:NO];
	[window setAlphaValue:focusedAlphaValue];
	
  // Attempt to restore previous water values, currently broken
	//NSDictionary *oldValues = [oldWindowValues objectForKey:[NSValue valueWithPointer:window]];
	//if (oldValues)
	//{
	//	[window setOpaque:[[oldValues objectForKey:@"opaque"] boolValue]];
	//	[window setAlphaValue:[[oldValues objectForKey:@"alphaValue"] doubleValue]];
	//}
}

@end
