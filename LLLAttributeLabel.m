//
//  LLLAttributeLabel.m
//  SouFun
//
//  Created by Qianlong Xu on 14-11-13.
//
//

#import "LLLAttributeLabel.h"


@interface LLLAttributeLabel()

@property (readwrite, nonatomic, strong) NSArray *links;
@property (readwrite, nonatomic, strong) NSTextCheckingResult *activeLink;
@property (nonatomic,assign) NSUInteger matchKeyIdx;

@end

@implementation LLLAttributeLabel

//初始化的时候指定最大宽度
- (instancetype)initWithMaxWidth:(CGFloat)maxWidth
{
    return [self initWithMaxWidth:maxWidth attributeString:nil];
}

//初始化的时候指定指定最大宽度和一个属性字符串；
- (instancetype)initWithMaxWidth:(CGFloat)maxWidth attributeString:(NSMutableAttributedString *)attrString
{
    return [self initWithFrame:(CGRect){{0,0},{maxWidth,0}} attributeString:attrString];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.numberOfLines = 0;
        self.preferredMaxLayoutWidth = CGRectGetWidth(frame);
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame attributeString:(NSMutableAttributedString *)attrString
{
    self = [self initWithFrame:frame];
    if (self) {
        self.attributedText = attrString;
    }
    return self;
}

- (void)setLLLclickedKeyAttributeBlock:(void (^)(NSString *, NSUInteger))LLLclickedKeyAttributeBlock
{
    if (LLLclickedKeyAttributeBlock) {
        self.userInteractionEnabled = YES;
        self.multipleTouchEnabled = NO;
        _LLLclickedKeyAttributeBlock = LLLclickedKeyAttributeBlock;
    }else{
        self.userInteractionEnabled = NO;
        _LLLclickedKeyAttributeBlock = nil;
    }
}

- (void)setText:(NSString *)tx TextColor:(UIColor *)col Font:(UIFont *)aFont
{
    if (tx && tx.length > 0) {
        NSMutableAttributedString *mutaString = [[NSMutableAttributedString alloc]initWithString:tx];
        NSRange range = NSMakeRange(0, tx.length);
        if (col) {
            [mutaString addAttribute:NSForegroundColorAttributeName value:col range:range];
        }
        if (aFont) {
            [mutaString addAttribute:NSFontAttributeName value:aFont range:range];
        }
        self.attributedText = mutaString;
    }
}

- (void)addTextColor:(UIColor *)col Font:(UIFont *)font range:(NSRange)range
{
    if (col) {
        [self addAttribute:NSForegroundColorAttributeName value:col range:range];
    }
    if (font) {
        [self addAttribute:NSFontAttributeName value:font range:range];
    }
}

- (void)addTextColor:(UIColor *)col Font:(UIFont *)font keyString:(NSString *)keyString
{
    if(isNotEmptyNotNullString(keyString)){
        NSRange range = [self.attributedText.string rangeOfString:keyString];
        [self addTextColor:col Font:font range:range];
    }
}

- (void)addAttribute:(NSString *)name value:(id)value range:(NSRange)range
{
    if (name && value) {
        NSMutableAttributedString *mulString = [[NSMutableAttributedString alloc]initWithAttributedString:self.attributedText];
        [mulString addAttribute:name value:value range:range];
        self.attributedText = [[NSAttributedString alloc]initWithAttributedString:mulString];
    }
}

- (void)addAttribute:(NSDictionary *)dic range:(NSRange)range
{
    if (dic) {
        NSMutableAttributedString *mulString = [[NSMutableAttributedString alloc]initWithAttributedString:self.attributedText];
        [mulString addAttributes:dic range:range];
        self.attributedText = [[NSAttributedString alloc]initWithAttributedString:mulString];
    }
}

- (void)deleteAllLink
{
    self.links = nil;
}

- (void)addLinkTextColor:(UIColor *)col Font:(UIFont *)font range:(NSRange)range
{
    if (range.length > 0) {
        [self addTextColor:col Font:font range:range];
        //    加上下划线
        [self addAttribute:NSUnderlineStyleAttributeName value:@1 range:range];
        [self addLinkWithTextCheckingResult:[NSTextCheckingResult linkCheckingResultWithRange:range URL:nil]];
    }
}

- (void)addLinkTextColor:(UIColor *)col Font:(UIFont *)font keyString:(NSString *)keyString
{
    if(isNotEmptyNotNullString(keyString)){
        NSRange range = [self.attributedText.string rangeOfString:keyString];
        [self addLinkTextColor:col Font:font range:range];
    }
}

- (void)fixLineHeight:(CGFloat)lineHeight
{
    NSMutableParagraphStyle * paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:lineHeight];
    [paragraphStyle setAlignment:0];
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    [self addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [self.attributedText.string length])];
}

- (CTFramesetterRef)framesetter
{
   return CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.attributedText);
}

- (CGRect)resetRectAfterSetAttributeFinished
{
    CGRect rect = self.frame;
    rect.size = [self getLLLLabelSize];
    self.frame = rect;
    return rect;
}

- (CGSize)getLLLLabelSize
{
    if (!self.attributedText) {
        return CGSizeZero;
    }
    
    CGSize constraints = CGSizeMake(CGRectGetWidth(self.frame), 5000);
    CTFramesetterRef ref = [self framesetter];
    CGSize textSize = CTFramesetterSuggestFrameSizeWithConstraints(ref, CFRangeMake(0, (CFIndex)[self.attributedText length]), NULL,constraints , NULL);
    CFRelease(ref);
    textSize = CGSizeMake(ceil(textSize.width), ceil(textSize.height));
    
    return textSize;
}

- (CFIndex)characterIndexAtPoint:(CGPoint)p
{
    CGRect textRect = self.bounds; //[self textRectForBounds:self.bounds limitedToNumberOfLines:self.numberOfLines];
    if (!CGRectContainsPoint(textRect, p)) {
        return NSNotFound;
    }
    textRect.size.height += 10;
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, textRect);
    
    CTFramesetterRef framesetterRef = [self framesetter];
    CTFrameRef frame = CTFramesetterCreateFrame(framesetterRef, CFRangeMake(0, (CFIndex)[self.attributedText length]), path, NULL);
    CFRelease(path);
    CFRelease(framesetterRef);
    
    if (frame == NULL) {
        return NSNotFound;
    }
    
    CFArrayRef lines = CTFrameGetLines(frame);
    NSInteger numberOfLines = CFArrayGetCount(lines);
    
    if (numberOfLines == 0) {
        CFRelease(frame);
        return NSNotFound;
    }
    
    CFIndex idx = NSNotFound;
    
    CGPoint lineOrigins[numberOfLines];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, numberOfLines), lineOrigins);
    
    // Offset tap coordinates by textRect origin to make them relative to the origin of frame
    //    p = CGPointMake(p.x - textRect.origin.x, p.y - textRect.origin.y);
    // Convert tap coordinates (start at top left) to CT coordinates (start at bottom left)
    p = CGPointMake(p.x, textRect.size.height - p.y);
    
    for (CFIndex lineIndex = 0; lineIndex < numberOfLines; lineIndex++) {
        CGPoint lineOrigin = lineOrigins[lineIndex];
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        
        // Get bounding information of line
        CGFloat ascent = 0.0f, descent = 0.0f, leading = 0.0f;
        CGFloat width = (CGFloat)CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        CGFloat yMin = (CGFloat)floor(lineOrigin.y - descent);
        CGFloat yMax = (CGFloat)ceil(lineOrigin.y + ascent);
        
        // Check if we've already passed the line
        if (p.y > yMax) {
            break;
        }
        // Check if the point is within this line vertically
        if (p.y >= yMin) {
            // Check if the point is within this line horizontally
            if (p.x >= lineOrigin.x && p.x <= lineOrigin.x + width) {
                // Convert CT coordinates to line-relative coordinates
                CGPoint relativePoint = CGPointMake(p.x - lineOrigin.x, p.y - lineOrigin.y);
                idx = CTLineGetStringIndexForPosition(line, relativePoint);
                break;
            }
        }
    }
    
    CFRelease(frame);
    
    return idx;
}

- (void)addLinkWithTextCheckingResult:(NSTextCheckingResult *)result
{
    NSMutableArray *mutableLinks = [NSMutableArray arrayWithArray:self.links];
    [mutableLinks addObject:result];
    self.links = [NSArray arrayWithArray:mutableLinks];
}

- (NSTextCheckingResult *)linkAtPoint:(CGPoint)point {
    CFIndex idx = [self characterIndexAtPoint:point];
    if (idx == NSNotFound) {
        self.matchKeyIdx = 0;
        return nil;
    }
    return [self linkAtCharacterIndex:idx];
}

- (NSTextCheckingResult *)linkAtCharacterIndex:(CFIndex)cfIdx {
     self.matchKeyIdx = 0;
    __block NSTextCheckingResult *result = nil;
    [self.links enumerateObjectsUsingBlock:^(NSTextCheckingResult *obj, NSUInteger idx, BOOL *stop) {
        if (NSLocationInRange((NSUInteger)cfIdx, obj.range)) {
            self.matchKeyIdx = idx;
            result = obj;
            *stop = YES;
        }
    }];
    return result;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    
    DebugLog(@"touched....");
    
    self.activeLink = [self linkAtPoint:[touch locationInView:self]];
    if (!self.activeLink) {
        [super touchesEnded:touches withEvent:event];
    }else{
        DebugLog(@"task....");
        if (self.LLLclickedKeyAttributeBlock) {
            NSString *str = [self.attributedText.string substringWithRange:self.activeLink.range];
            self.LLLclickedKeyAttributeBlock(str,self.matchKeyIdx);
        }
    }
}


//- (CGSize)sizeThatFits:(CGSize)size {
//    if (!self.attributedText) {
//        return [super sizeThatFits:size];
//    } else {
//        size = [self getLLLLabelSize];
//        return size;
//    }
//}
//
//- (CGSize)intrinsicContentSize {
//    
//    // There's an implicit width from the original UILabel implementation
//    return [self sizeThatFits:[super intrinsicContentSize]];
//}

//- (void)drawTextInRect:(CGRect)rect
//{
//    if (!self.resultAttributedString) {
//        [super drawTextInRect:rect];
//        return;
//    }
//
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    
//    CGContextSaveGState(context);
//    //将当前context的坐标系进行flip,否则上下颠倒
//    CGAffineTransform flipVertical = CGAffineTransformMake(1,0,0,-1,0,self.bounds.size.height);
//    CGContextConcatCTM(context, flipVertical);
//    //设置字形变换矩阵为CGAffineTransformIdentity，也就是说每一个字形都不做图形变换
//    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
//    
//    CTTextAlignment alignment = self.ctAligment; //文本对齐方式
//    CTParagraphStyleSetting alignmentStyle;
//    //指定为对齐属性
//    alignmentStyle.spec      = kCTParagraphStyleSpecifierAlignment;
//    alignmentStyle.valueSize = sizeof(alignment);
//    alignmentStyle.value     = &alignment;
//    
//    //设置行距,解决5,5s在7.1上运行效果不一样
//    CGFloat _linespace = 24;
//    CTParagraphStyleSetting lineSpaceSetting;
//    lineSpaceSetting.spec = kCTParagraphStyleSpecifierLineSpacing;
//    lineSpaceSetting.value = &_linespace;
//    lineSpaceSetting.valueSize = sizeof(float);
//    
//    CGFloat _linespace2 = 25;
//    CTParagraphStyleSetting lineMaxSpaceSetting;
//    lineSpaceSetting.spec = kCTParagraphStyleSpecifierMaximumLineHeight;
//    lineSpaceSetting.value = &_linespace2;
//    lineSpaceSetting.valueSize = sizeof(float);
//    
//    CGFloat _linespace3 = 25;
//    CTParagraphStyleSetting lineMinSpaceSetting;
//    lineSpaceSetting.spec = kCTParagraphStyleSpecifierMinimumLineHeight;
//    lineSpaceSetting.value = &_linespace3;
//    lineSpaceSetting.valueSize = sizeof(float);
//
//    CTParagraphStyleSetting settings[] = {alignmentStyle,lineSpaceSetting,lineMinSpaceSetting,lineMaxSpaceSetting};//设置样式
//    
//    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings, sizeof(settings));
//    
//    //给字符串添加样式attribute
//    [self.resultAttributedString addAttribute:(id)kCTParagraphStyleAttributeName
//                                        value:(__bridge id)paragraphStyle
//                                        range:NSMakeRange(0, [self.resultAttributedString length])];
//    CTFramesetterRef framesetter = [self framesetter];
//    CGMutablePathRef pathRef = CGPathCreateMutable();
//    CGPathAddRect(pathRef,NULL , CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height));
//    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), pathRef,NULL );
//    CFArrayRef lines = CTFrameGetLines(frame);
//    self.numberOfLines = CFArrayGetCount(lines);
//    
//    CGContextSetTextPosition(context, 0, 0);
//    CTFrameDraw(frame, context);
//    CGContextRestoreGState(context);
//    
//    CFRelease(paragraphStyle);
//    CGPathRelease(pathRef);
//    CFRelease(framesetter);
//    CFRelease(frame);
//    
//    [self.text drawInRect:rect withAttributes:nil];
////    NSString *src = @"dfd修改windows回车换行为mac的回车换行f";
////
////    //修改windows回车换行为mac的回车换行
////    //src = [src stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
////    
////    NSMutableAttributedString * mabstring = [[NSMutableAttributedString alloc]initWithString:src];
////    
////    long slen = [mabstring length];
////    
////    
////    //创建文本对齐方式
////    CTTextAlignment alignment = kCTRightTextAlignment;//kCTNaturalTextAlignment;
////    CTParagraphStyleSetting alignmentStyle;
////    alignmentStyle.spec=kCTParagraphStyleSpecifierAlignment;//指定为对齐属性
////    alignmentStyle.valueSize=sizeof(alignment);
////    alignmentStyle.value=&alignment;
////    
////    //首行缩进
////    CGFloat fristlineindent = 24.0f;
////    CTParagraphStyleSetting fristline;
////    fristline.spec = kCTParagraphStyleSpecifierFirstLineHeadIndent;
////    fristline.value = &fristlineindent;
////    fristline.valueSize = sizeof(float);
////    
////    //段缩进
////    CGFloat headindent = 10.0f;
////    CTParagraphStyleSetting head;
////    head.spec = kCTParagraphStyleSpecifierHeadIndent;
////    head.value = &headindent;
////    head.valueSize = sizeof(float);
////    
////    //段尾缩进
////    CGFloat tailindent = 50.0f;
////    CTParagraphStyleSetting tail;
////    tail.spec = kCTParagraphStyleSpecifierTailIndent;
////    tail.value = &tailindent;
////    tail.valueSize = sizeof(float);
////    
////    //tab
////    CTTextAlignment tabalignment = kCTJustifiedTextAlignment;
////    CTTextTabRef texttab = CTTextTabCreate(tabalignment, 24, NULL);
////    CTParagraphStyleSetting tab;
////    tab.spec = kCTParagraphStyleSpecifierTabStops;
////    tab.value = &texttab;
////    tab.valueSize = sizeof(CTTextTabRef);
////    
////    //换行模式
////    CTParagraphStyleSetting lineBreakMode;
////    CTLineBreakMode lineBreak = kCTLineBreakByTruncatingMiddle;//kCTLineBreakByWordWrapping;//换行模式
////    lineBreakMode.spec = kCTParagraphStyleSpecifierLineBreakMode;
////    lineBreakMode.value = &lineBreak;
////    lineBreakMode.valueSize = sizeof(CTLineBreakMode);
////    
////    //多行高
////    CGFloat MutiHeight = 10.0f;
////    CTParagraphStyleSetting Muti;
////    Muti.spec = kCTParagraphStyleSpecifierLineHeightMultiple;
////    Muti.value = &MutiHeight;
////    Muti.valueSize = sizeof(float);
////    
////    //最大行高
////    CGFloat MaxHeight = 5.0f;
////    CTParagraphStyleSetting Max;
////    Max.spec = kCTParagraphStyleSpecifierLineHeightMultiple;
////    Max.value = &MaxHeight;
////    Max.valueSize = sizeof(float);
////    
////    //行距
////    CGFloat _linespace = 5.0f;
////    CTParagraphStyleSetting lineSpaceSetting;
////    lineSpaceSetting.spec = kCTParagraphStyleSpecifierLineSpacing;
////    lineSpaceSetting.value = &_linespace;
////    lineSpaceSetting.valueSize = sizeof(float);
////    
////    //段前间隔
////    CGFloat paragraphspace = 5.0f;
////    CTParagraphStyleSetting paragraph;
////    paragraph.spec = kCTParagraphStyleSpecifierLineSpacing;
////    paragraph.value = &paragraphspace;
////    paragraph.valueSize = sizeof(float);
////
//    
////    //书写方向
////    CTWritingDirection wd = kCTWritingDirectionRightToLeft;
////    CTParagraphStyleSetting writedic;
////    writedic.spec = kCTParagraphStyleSpecifierBaseWritingDirection;
////    writedic.value = &wd;
////    writedic.valueSize = sizeof(CTWritingDirection);
////    
////    //组合设置
////    CTParagraphStyleSetting settings[] = {
////        alignmentStyle,
////        fristline,
////        head,
////        tail,
////        tab,
////        lineBreakMode,
////        Muti,
////        Max,
////        lineSpaceSetting,
////        writedic
////    };
////    
////    //通过设置项产生段落样式对象
////    CTParagraphStyleRef style = CTParagraphStyleCreate(settings, 11);
////    
////    // build attributes
////    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObject:(__bridge id)style forKey:(id)kCTParagraphStyleAttributeName ];
////    
////    // set attributes to attributed string
////    [mabstring addAttributes:attributes range:NSMakeRange(0, slen)];
////    
////    
////    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)mabstring);
////    
////    CGMutablePathRef Path = CGPathCreateMutable();
////    
////    //坐标点在左下角
////    CGPathAddRect(Path, NULL ,CGRectMake(10 , 10 ,self.bounds.size.width-20 , self.bounds.size.height-20));
////    
////    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), Path, NULL);
////    
////    
////    
////    //获取当前(View)上下文以便于之后的绘画，这个是一个离屏。
////    CGContextRef context = UIGraphicsGetCurrentContext();
////    
////    CGContextSetTextMatrix(context , CGAffineTransformIdentity);
////    
////    //压栈，压入图形状态栈中.每个图形上下文维护一个图形状态栈，并不是所有的当前绘画环境的图形状态的元素都被保存。图形状态中不考虑当前路径，所以不保存
////    //保存现在得上下文图形状态。不管后续对context上绘制什么都不会影响真正得屏幕。
////    CGContextSaveGState(context);
////    
////    //x，y轴方向移动
////    CGContextTranslateCTM(context , 0 ,self.bounds.size.height);
////    
////    //缩放x，y轴方向缩放，－1.0为反向1.0倍,坐标系转换,沿x轴翻转180度
////    CGContextScaleCTM(context, 1.0 ,-1.0);
////    
////    CTFrameDraw(frame,context);
////    
////    CGPathRelease(Path);
////    CFRelease(framesetter);
////    
//    
//
//}

@end
