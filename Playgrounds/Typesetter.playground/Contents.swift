//: Playground - noun: a place where people can play
import UIKit
import XCPlayground

struct Margin {
    var top:CGFloat
    var left:CGFloat
    var right:CGFloat
    var bottom:CGFloat
}

func textSizeWithFont(text:String, font:UIFont)->CGSize {
    let label   = UILabel(frame: CGRectMake(0,0,50,50))
    label.font  = font
    label.text  = text
    label.sizeToFit()
    return label.frame.size
}

var novel_snippets = "唐帝国天启十三年春，渭城下了一场雨。\n这座位于帝国广阔疆域西北端的军事边城，为了防范草原上野蛮人入侵，四向的土制城墙被垒得极为厚实，看上去就像是一个墩实的土围子。\n干燥时节土墙上的浮土被西北的风刀子一刮便会四处飘腾，然后落在简陋的营房上，落在兵卒们的身上，整个世界都将变成一片土黄色，人们夜里入睡抖铺盖时都会抖起一场沙尘暴。\n正在春旱，这场雨来的恰是时辰，受到军卒们的热烈欢迎，从昨夜至此时的淅淅沥沥雨点洗涮掉屋顶的灰尘，仿佛也把人们的眼睛也洗的明亮了很多。\n至少马士襄此时的眼睛很亮。\n做为渭城最高军事长官，他此时的态度很谦卑，虽然对于名贵毛毯上那些黄泥脚印有些不满，却成功地将那种不满掩饰成为一丝恰到好处的惊愕。\n对着矮几旁那位穿着肮脏袍子的老人恭敬行了一礼，他低声请示道：“尊敬的老大人，不知道帐里的贵人还有没有什么别的需要，如果贵人坚持明天就出发，那么我随时可以拨出一个百人队护卫随行，军部那边我马上做记档传过去。”\n那位老人温和笑了笑，指了指帐里那几个人影，摇摇头表示自己并没有什么意见。就在这时，一道冷漠骄傲的女子声音从帐里传出：“不用了，办好你自己的差事吧。”\n今天清晨，对方的车队冒雨冲入渭城后，马士襄没有花多长时间便猜到了车队里那位贵人的身份，所以对于对方的骄傲冷漠没有任何意见，不敢有任何意见。\n帐里的人沉默片刻，忽然开口说道：“从渭城往都城，岷山这一带道路难行，看样子这场雨还要下些时日，说不定有些山路会被冲毁……你从军中给我调个向导。”\n马士襄怔了怔，想起某个可恶的家伙，沉默片刻后低头回应道：“有现成的人选。”"

var font        = UIFont.systemFontOfSize(16)
var margin      = Margin(top: 8,left: 8,right: 8,bottom: 8)
var fontWidth   = textSizeWithFont("宽", font: font)

extension String {
    var length: Int {
        return characters.count
    }
}

func makeFrame(content: String, bounds: CGRect, font: UIFont, margin: Margin)->CTFrameRef {
    var aligment        = CTTextAlignment.Justified
    var lineSpace       = 8.0
    var paraSpace       = 12.0
    var lineBreak       = CTLineBreakMode.ByCharWrapping
    var firstHeadIndent = fontWidth.width * 2.0
    let settings        = [
        CTParagraphStyleSetting(spec: .Alignment, valueSize: sizeofValue(aligment), value: &aligment),
        CTParagraphStyleSetting(spec: .LineSpacing, valueSize: sizeofValue(lineSpace), value: &lineSpace),
        CTParagraphStyleSetting(spec: .LineBreakMode, valueSize: sizeofValue(lineBreak), value: &lineBreak),
        CTParagraphStyleSetting(spec: .ParagraphSpacing, valueSize: sizeofValue(paraSpace), value: &paraSpace),
        CTParagraphStyleSetting(spec: .FirstLineHeadIndent, valueSize: sizeofValue(firstHeadIndent), value: &firstHeadIndent)
    ]
    
    let attrContent = NSMutableAttributedString(string: content)
    let range       = NSMakeRange(0, attrContent.length)
    let style       = CTParagraphStyleCreate(settings, 5)
    
    attrContent.addAttribute(NSFontAttributeName, value: font, range: range)
    attrContent.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor(), range: range)
    CFAttributedStringSetAttribute(attrContent, CFRangeMake(0, range.length), kCTParagraphStyleAttributeName, style)
    
    let frameSetter = CTFramesetterCreateWithAttributedString(attrContent as CFAttributedStringRef)
    let path        = CGPathCreateMutable()
    let container   = CGRectMake(
        bounds.origin.x + margin.left,
        bounds.origin.y + margin.top,
        bounds.size.width - margin.left - margin.right,
        bounds.size.height - margin.top - margin.bottom
    )

    
    CGPathAddRect(path, nil, container)
    return CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, range.length), path, nil)
}

class PageView: UIView {
    var textFrame:CTFrameRef?
    
    override func drawRect(rect: CGRect) {
        if let _ = textFrame {
            let ctx = UIGraphicsGetCurrentContext();
            CGContextSetTextMatrix(ctx, CGAffineTransformIdentity)
            CGContextTranslateCTM(ctx, 0, self.bounds.size.height)
            CGContextScaleCTM(ctx, 1.0, -1.0)
            CTFrameDraw(textFrame!, ctx!)
        }
    }
}

var pageView      = PageView(frame: CGRectMake(margin.left, margin.top, 360, 720))

// 排版
var drawFrame     = makeFrame(novel_snippets, bounds: pageView.bounds, font: font, margin:margin)

// 截取可见字符
var visibleRange  = CTFrameGetVisibleStringRange(drawFrame).length
var subIndex      = novel_snippets.startIndex.advancedBy(visibleRange)
var visibleString = novel_snippets.substringToIndex(subIndex)

// 绘制
pageView.textFrame  = drawFrame
pageView.setNeedsDisplay()

XCPlaygroundPage.currentPage.liveView = pageView



