//
// Copyright (c) 2013 Robert Wijas. All rights reserved.
//

#import "UISSTextAttributesValueConverter.h"
#import "UISSFontValueConverter.h"
#import "UISSColorValueConverter.h"
#import "UISSOffsetValueConverter.h"
#import "UISSArgument.h"

@interface UISSTextAttributesValueConverter ()

@property(nonatomic, strong) UISSFontValueConverter *fontConverter;
@property(nonatomic, strong) UISSColorValueConverter *colorConverter;
@property(nonatomic, strong) UISSOffsetValueConverter *offsetConverter;

@end

@implementation UISSTextAttributesValueConverter

- (id)init
{
    self = [super init];
    if (self) {
        self.fontConverter = [[UISSFontValueConverter alloc] init];
        self.colorConverter = [[UISSColorValueConverter alloc] init];
        self.offsetConverter = [[UISSOffsetValueConverter alloc] init];
    }
    return self;
}

- (BOOL)canConvertValueForArgument:(UISSArgument *)argument
{
    return [argument.type hasPrefix:@"@"] && [[argument.name lowercaseString] hasSuffix:@"textattributes"] && [argument.value isKindOfClass:[NSDictionary class]];
}

- (void)convertProperty:(NSString *)propertyName fromDictionary:(NSDictionary *)dictionary
           toDictionary:(NSMutableDictionary *)converterDictionary withKey:(NSString *)key
         usingConverter:(id<UISSArgumentValueConverter>)converter;
{
    id value = [dictionary objectForKey:propertyName];
    if (value) {
        id converted = [converter convertValue:value];
        if (converted) {
            [converterDictionary setObject:converted forKey:key];
        }
    }
}

- (id)convertValue:(id)value;
{
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = (NSDictionary *) value;

        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        [self convertProperty:UISS_FONT_KEY fromDictionary:dictionary toDictionary:attributes withKey:NSFontAttributeName
               usingConverter:self.fontConverter];

        [self convertProperty:UISS_TEXT_COLOR_KEY fromDictionary:dictionary toDictionary:attributes withKey:NSForegroundColorAttributeName
               usingConverter:self.colorConverter];

        id shadowColorString = [dictionary objectForKey:UISS_TEXT_SHADOW_COLOR_KEY];
        id shadowOffsetString = [dictionary objectForKey:UISS_TEXT_SHADOW_OFFSET_KEY];
        if (shadowColorString && shadowColorString != [NSNull null]) {
            NSShadow *shadow = [[NSShadow alloc] init];
            UIColor *color = [self.colorConverter convertValue:shadowColorString];
            if (color) {
                [shadow setShadowColor:color];
                if (shadowOffsetString && shadowOffsetString != [NSNull null]) {
                    NSValue *offsetValue = [self.offsetConverter convertValue:shadowOffsetString];
                    if (offsetValue) {
                        CGSize offset = CGSizeMake(0, 0);
                        [offsetValue getValue:&offset];
                        [shadow setShadowOffset:offset];
                    }
                }
                attributes[NSShadowAttributeName] = shadow;
            }
        }
        
        if (attributes.count) {
            return attributes;
        }
    }

    return nil;
}

- (NSString *)generateCodeForValue:(id)value
{
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = (NSDictionary *) value;

        NSMutableString *objectAndKeys = [NSMutableString string];

        id fontValue = [dictionary objectForKey:UISS_FONT_KEY];
        if (fontValue) {
            [objectAndKeys appendFormat:@"%@, %@,", [self.fontConverter generateCodeForValue:fontValue], @"UITextAttributeFont"];
        }

        id textColorValue = [dictionary objectForKey:UISS_TEXT_COLOR_KEY];
        if (textColorValue) {
            [objectAndKeys appendFormat:@"%@, %@,", [self.colorConverter generateCodeForValue:textColorValue], @"UITextAttributeTextColor"];
        }

        id textShadowColor = [dictionary objectForKey:UISS_TEXT_SHADOW_COLOR_KEY];
        if (textShadowColor) {
            [objectAndKeys appendFormat:@"%@, %@,", [self.colorConverter generateCodeForValue:textShadowColor], @"UITextAttributeTextShadowColor"];
        }

        id textShadowOffset = [dictionary objectForKey:UISS_TEXT_SHADOW_OFFSET_KEY];
        if (textShadowOffset) {
            [objectAndKeys appendFormat:@"[NSValue valueWithUIOffset:%@], %@,", [self.offsetConverter generateCodeForValue:textShadowOffset], @"UITextAttributeTextShadowOffset"];
        }

        if (objectAndKeys.length) {
            return [NSString stringWithFormat:@"[NSDictionary dictionaryWithObjectsAndKeys:%@ nil]", objectAndKeys];
        }
    }
    
    return nil;
}

@end
