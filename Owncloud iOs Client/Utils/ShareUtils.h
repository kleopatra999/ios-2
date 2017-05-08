//
//  ShareUtils.h
//  Owncloud iOs Client
//
//  Created by Gonzalo Gonzalez on 25/1/16.
//

/*
 Copyright (C) 2016, ownCloud GmbH.
 This code is covered by the GNU Public License Version 3.
 For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 You should have received a copy of this license
 along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 */

#import <Foundation/Foundation.h>
#import "OCShareUser.h"
#import "AppDelegate.h"
#import "OCCommunication.h"
#import "constants.h"
#import "Customization.h"
#import "UtilsUrls.h"
#import "FileNameUtils.h"
#import "OCErrorMsg.h"

@interface ShareUtils : NSObject

+ (NSMutableArray *) manageTheDuplicatedUsers: (NSMutableArray*) items;

+ (NSURL *) getNormalizedURLOfShareLink:(NSString *) url;

+ (BOOL) isPasswordEnforcedCapabilityEnabled;

+ (NSString *) getPasswordEncodingWithPassword:(NSString *)password;


//network to move methods

///-----------------------------------
/// @name Add new share link
///-----------------------------------

/**
 * Method to add new share link
 *
 * @param
 */
+ (void) createNewShareLink:(OCSharedDto *)shareLink ofFile:(FileDto *)file;

//updateshare

@end
