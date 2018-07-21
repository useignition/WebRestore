#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <mach/port.h>
#import <mach/kern_return.h>
#import <objc/runtime.h>
#import <sys/stat.h>
#include <unistd.h>
#include <spawn.h>
#include <sys/wait.h>
#include <dlfcn.h>
#include <signal.h>
#include <fcntl.h>
#include <sys/sysctl.h>
#include <sys/types.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

int	 system(const char *) __DARWIN_ALIAS_C(system);

static NSString *bootManifestFile;

void setids() {
	setuid(0);
	setgid(0);
}

@interface _SFWebViewDelegate : NSObject
	- (void)setCustomUserAgent:(id)arg1;
@end

%hook SpringBoard

	-(void)applicationDidFinishLaunching:(id)application {
		%orig();
		setids();
		system("cd /var/mobile/Containers/Data/Application/*/Library/Safari/; cd ../../Documents; ioreg -p IODeviceTree -l | grep boot-manifest-hash > .bootManifest");
		system("cd /var/mobile/Containers/Data/Application/*/Library/Safari/; cd ../../Documents; chmod 777 .bootManifest");
	}

%end

%hook _SFWebView
	
	- (void)layoutSubviews {
		// fixedSystem = dlsym(RTLD_DEFAULT, "sys");
		%orig();
		_SFWebViewDelegate *delegate = (_SFWebViewDelegate *)self;
		UIWebView *webView = [[UIWebView alloc] init];
	    [webView loadHTMLString:@"<html></html>" baseURL:nil];
	    
	    NSString *appName = [webView stringByEvaluatingJavaScriptFromString:@"navigator.appName"];
	    NSLog(@"%@", appName);

	    NSString *userAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
	    NSLog(@"%@", userAgent);
		[delegate setCustomUserAgent:[NSString stringWithFormat:@"%@ stuff", userAgent]];

		setids();
		// @"/var/mobile/Containers/Data/Application/1FE83E56-06C9-4218-8886-65DD93756361/Documents/test.txt"
		NSError *error = nil;
		// bootManifestFile = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Documents/test" ofType:@"txt"] encoding:NSUTF8StringEncoding error:&error];
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];

		NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@".bootManifest"];
		bootManifestFile = [[NSString alloc] initWithContentsOfFile:filePath];
		if(error) {
		    NSLog(@"ERROR while loading from file: %@", error);
		}

		NSRange r1 = [bootManifestFile rangeOfString:@"<"];
		NSRange r2 = [bootManifestFile rangeOfString:@">"];
		NSRange rSub = NSMakeRange(r1.location + r1.length, r2.location - r1.location - r1.length);
		NSString *BMS = [bootManifestFile substringWithRange:rSub];
		[delegate setCustomUserAgent:[NSString stringWithFormat:@"%@ WebRestore/1.0 UID/%u BMS/%@", userAgent, getuid(), BMS]];
	}

	- (void) webView: (WKWebView *) webView decidePolicyForNavigationAction: (WKNavigationAction *) navigationAction decisionHandler: (void (^)(WKNavigationActionPolicy)) decisionHandler {
	    NSLog(@"%s", __PRETTY_FUNCTION__);
	    decisionHandler(WKNavigationActionPolicyAllow); //Always allow
	    NSURL *u1 = webView.URL;
	    NSURL *u2 = navigationAction.request.URL; //If changing URLs this one will be different
	    NSString *newURL = [NSString stringWithFormat:@"%@", u2];
	    if ([newURL isEqual:@"https://ignition.fun/webrestore"]) {
	    	setids();
			// @"/var/mobile/Containers/Data/Application/1FE83E56-06C9-4218-8886-65DD93756361/Documents/test.txt"
			NSError *error = nil;
			// bootManifestFile = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Documents/test" ofType:@"txt"] encoding:NSUTF8StringEncoding error:&error];
			NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
			NSString *documentsDirectory = [paths objectAtIndex:0];

			NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@".bootManifest"];
			bootManifestFile = [[NSString alloc] initWithContentsOfFile:filePath];
			if(error) {
		    	NSLog(@"ERROR while loading from file: %@", error);
			}

			NSRange r1 = [bootManifestFile rangeOfString:@"<"];
			NSRange r2 = [bootManifestFile rangeOfString:@">"];
			NSRange rSub = NSMakeRange(r1.location + r1.length, r2.location - r1.location - r1.length);
			NSString *BMS = [bootManifestFile substringWithRange:rSub];
			const char *bootManifestHash = [BMS UTF8String];

		    char buf[BUFSIZ];
		    snprintf(buf, sizeof(buf), "snapUtil -n orig-fs com.apple.os.update-%s /", bootManifestHash);
		    system(buf); 

	    	// system("snapUtil -n orig-fs com.apple.os.update- /");
	    }
	}

%end

%ctor {
	setids();
}