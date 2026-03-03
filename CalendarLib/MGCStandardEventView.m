//
//  MGCStandardEventView.m
//  Graphical Calendars Library for iOS
//
//  Distributed under the MIT License
//  Get the latest version from here:
//
//	https://github.com/jumartin/Calendar
//
//  Copyright (c) 2014-2015 Julien Martin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#import "MGCStandardEventView.h"

static CGFloat kSpace = 2;


static UIColor *MGCColorFromHexString(NSString *hexString)
{
	if (![hexString isKindOfClass:[NSString class]]) return nil;

	NSString *cleanString = [[hexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
	if ([cleanString hasPrefix:@"#"]) {
		cleanString = [cleanString substringFromIndex:1];
	}

	if (cleanString.length == 3) {
		unichar r = [cleanString characterAtIndex:0];
		unichar g = [cleanString characterAtIndex:1];
		unichar b = [cleanString characterAtIndex:2];
		cleanString = [NSString stringWithFormat:@"%C%C%C%C%C%C", r, r, g, g, b, b];
	}

	if (cleanString.length != 6 && cleanString.length != 8) return nil;

	unsigned int colorValue = 0;
	if (![[NSScanner scannerWithString:cleanString] scanHexInt:&colorValue]) return nil;

	CGFloat alpha = 1.0;
	CGFloat red = 0.0;
	CGFloat green = 0.0;
	CGFloat blue = 0.0;

	if (cleanString.length == 8) {
		alpha = ((colorValue >> 24) & 0xFF) / 255.0;
		red = ((colorValue >> 16) & 0xFF) / 255.0;
		green = ((colorValue >> 8) & 0xFF) / 255.0;
		blue = (colorValue & 0xFF) / 255.0;
	}
	else {
		red = ((colorValue >> 16) & 0xFF) / 255.0;
		green = ((colorValue >> 8) & 0xFF) / 255.0;
		blue = (colorValue & 0xFF) / 255.0;
	}

	return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}


static UIColor *MGCResolveColorFromInput(id value, UIColor *fallbackColor)
{
	if ([value isKindOfClass:[UIColor class]]) {
		return value;
	}

	if (value) {
		CFTypeRef cfValue = (__bridge CFTypeRef)value;
		if (CFGetTypeID(cfValue) == CGColorGetTypeID()) {
			return [UIColor colorWithCGColor:(CGColorRef)cfValue];
		}
	}

	if ([value isKindOfClass:[NSString class]]) {
		UIColor *parsedColor = MGCColorFromHexString(value);
		if (parsedColor) return parsedColor;
	}

	return fallbackColor;
}


@interface MGCStandardEventView ()

@property (nonatomic) UIView *leftBorderView;
@property (nonatomic) NSMutableAttributedString *attrString;

@end


@implementation MGCStandardEventView


- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
		self.contentMode = UIViewContentModeRedraw;
		
		_color = [UIColor blackColor];
		_statusColor = nil;
		_style = MGCStandardEventViewStylePlain|MGCStandardEventViewStyleSubtitle;
		_font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
		_leftBorderView = [[UIView alloc]initWithFrame:CGRectZero];
		[self addSubview:_leftBorderView];
	}
    return self;
}

- (void)redrawStringInRect:(CGRect)rect
{
	// attributed string can't be created with nil string
	NSMutableString *s = [NSMutableString stringWithString:@""];
	
	if (self.style & MGCStandardEventViewStyleDot) {
		[s appendString:@"\u2022 "]; // 25CF // 2219 // 30FB
	}
	
	if (self.title) {
		[s appendString:self.title];
	}
	
  UIFont *boldFont = [UIFont fontWithDescriptor:[[self.font fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:self.font.pointSize];
	UIFont *titleFont = [UIFont fontWithDescriptor:[self.font fontDescriptor] size:self.font.pointSize];
  // UIFont *boldFontSub = [UIFont fontWithDescriptor:[self.font fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];

	NSMutableAttributedString *as = [[NSMutableAttributedString alloc]initWithString:s attributes:@{NSFontAttributeName: titleFont ?: self.font }];
	
	if (self.subtitle && self.subtitle.length > 0 && self.style & MGCStandardEventViewStyleSubtitle) {
		NSMutableString *s  = [NSMutableString stringWithFormat:@"\n%@", self.subtitle];
    NSMutableAttributedString *subtitle = [[NSMutableAttributedString alloc]initWithString:s attributes:@{NSFontAttributeName: boldFont ?: self.font }];

		// NSMutableAttributedString *subtitle = [[NSMutableAttributedString alloc]initWithString:s attributes:@{NSFontAttributeName:self.font}];
		[as appendAttributedString:subtitle];
	}
	
	if (self.detail && self.detail.length > 0 && self.style & MGCStandardEventViewStyleDetail) {
		UIFont *smallFont = [UIFont fontWithDescriptor:[self.font fontDescriptor] size:self.font.pointSize - 2];
		NSMutableString *s = [NSMutableString stringWithFormat:@"\t%@", self.detail];
		NSMutableAttributedString *detail = [[NSMutableAttributedString alloc]initWithString:s attributes:@{NSFontAttributeName:smallFont}];
		[as appendAttributedString:detail];
	}
	
	NSTextTab *t = [[NSTextTab alloc]initWithTextAlignment:NSTextAlignmentRight location:rect.size.width options:[[NSDictionary alloc] init]];
	NSMutableParagraphStyle *style = [NSMutableParagraphStyle new];
	style.tabStops = @[t];
	//style.hyphenationFactor = .4;
	//style.lineBreakMode = NSLineBreakByTruncatingMiddle;
	[as addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, as.length)];
	
	UIColor *color = self.selected ? [UIColor whiteColor] : [UIColor blackColor];
	[as addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, as.length)];
	
	self.attrString = as;
}


- (void)layoutSubviews
{
	[super layoutSubviews];
	self.leftBorderView.frame = CGRectMake(0, 0, 2, self.bounds.size.height);
	[self setNeedsDisplay];
}

- (void)setColor:(UIColor*)color
{
	_color = MGCResolveColorFromInput(color, [UIColor blackColor]);
	[self resetColors];
}

- (void)setStatusColor:(UIColor *)statusColor
{
	_statusColor = MGCResolveColorFromInput(statusColor, nil);
	[self setNeedsDisplay];
}

- (void)setStatus:(NSString *)status
{
	_status = [status copy];
	[self setNeedsDisplay];
}

- (UIColor *)effectiveStatusColor
{
	if (self.statusColor) {
		return self.statusColor;
	}

	return self.selected ? [UIColor whiteColor] : [UIColor blackColor];
}

- (void)setStyle:(MGCStandardEventViewStyle)style
{
	_style = style;
	self.leftBorderView.hidden = !(_style & MGCStandardEventViewStyleBorder);
	[self resetColors];
}

- (void)resetColors
{
	self.leftBorderView.backgroundColor = self.color;
	
	if (self.selected)
		self.backgroundColor = self.selected ? self.color : [self.color colorWithAlphaComponent:.3];
	else if (self.style & MGCStandardEventViewStylePlain)
		self.backgroundColor = [self.color colorWithAlphaComponent:.3];
	else
		self.backgroundColor = [UIColor clearColor];
	
	[self setNeedsDisplay];
}

- (void)setSelected:(BOOL)selected
{
	[super setSelected:selected];
	[self resetColors];
}

- (void)setVisibleHeight:(CGFloat)visibleHeight
{
	[super setVisibleHeight:visibleHeight];
	[self setNeedsDisplay];
}

- (void)prepareForReuse
{
	[super prepareForReuse];
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	CGRect drawRect = CGRectInset(rect, kSpace, 0);
	if (self.style & MGCStandardEventViewStyleBorder) {
		drawRect.origin.x += kSpace;
		drawRect.size.width -= kSpace;
	}

	CGRect availableRect = drawRect;
	availableRect.size.height = fminf(availableRect.size.height, self.visibleHeight);
	CGRect textRect = availableRect;
	CGRect statusRect = CGRectZero;

	BOOL hasStatus = (self.status.length > 0);
	UIFont *statusFont = [UIFont fontWithDescriptor:[self.font fontDescriptor] size:MAX(self.font.pointSize - 1.0, 8.0)];
	if (hasStatus) {
		CGFloat statusHeight = ceil(statusFont.lineHeight);
		CGFloat reservedHeight = statusHeight + kSpace;
		if (availableRect.size.height > reservedHeight) {
			textRect.size.height -= reservedHeight;
			statusRect = CGRectMake(availableRect.origin.x,
									CGRectGetMaxY(textRect) + kSpace,
									availableRect.size.width,
									statusHeight);
		}
		else {
			textRect.size.height = 0;
			statusRect = availableRect;
		}
	}

	[self redrawStringInRect:textRect];

	if (textRect.size.height > 0) {
		CGRect boundingRect = [self.attrString boundingRectWithSize:CGSizeMake(textRect.size.width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil];

		if (boundingRect.size.height > textRect.size.height) {
			[self.attrString.mutableString replaceOccurrencesOfString:@"\n" withString:@"  " options:NSCaseInsensitiveSearch range:NSMakeRange(0, self.attrString.length)];
		}

		[self.attrString drawWithRect:textRect options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin context:nil];
	}

	if (hasStatus && statusRect.size.height > 0) {
		NSDictionary *statusAttributes = @{
			NSFontAttributeName: statusFont,
			NSForegroundColorAttributeName: [self effectiveStatusColor]
		};
		[self.status drawWithRect:statusRect options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin attributes:statusAttributes context:nil];
	}
}

#pragma mark - NSCopying protocol

- (id)copyWithZone:(NSZone *)zone
{
	MGCStandardEventView *cell = [super copyWithZone:zone];
	cell.title = self.title;
	cell.subtitle = self.subtitle;
	cell.detail = self.detail;
	cell.status = self.status;
	cell.statusColor = self.statusColor;
	cell.color = self.color;
	cell.style = self.style;
	
	return cell;
}

@end
