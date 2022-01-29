import ComposableArchitecture
import SwiftUI

public enum PeriodBarAction {}

struct PeriodBar : View {
  
  let content: PeriodBarContent

  @State private var opacity = 1.0
  
  var body: some View {
    
    GeometryReader { geometry in
      ZStack {
        Capsule()
//          .fill(LinearGradient(gradient: Gradient(colors: [ content.isPulsing ? content.fillColor : content.fillColor.opacity(0.85), content.fillColor.opacity(1.0), content.fillColor.opacity(1.0)]), startPoint: .top, endPoint: .bottom))
          .foregroundColor(content.fillColor)
          .mask {
            VStack {
              Spacer()
              Rectangle()
                .frame(height: ((geometry.size.height + 10) * content.percentage), alignment: .bottom)
                .offset(y: -0)
                .opacity(content.isPulsing ? opacity : 1.0)
            }
          }
          .background {
            Capsule()
              .foregroundColor(.blue).opacity(0.35)
          }
          .animation(.default, value: content)
//          .animation( content.isPulsing ?
//                        .linear(duration: 1.0).repeatForever(autoreverses: true)
//                      : .none, value: opacity)
//          .onAppear {
//              opacity = 0.55
//          }
        
        Spacer()
      }
//      .shadow(color: isGlowing ? .red.opacity(0.95) : .black, radius: 25, x: 25, y: 0)
    }
    .frame(height: 8 * 4.5)
    .frame(width: 8)
    
  }
}

public struct SessionViewContent: Equatable, Identifiable {
  public var periods: [PeriodBarContent]
  public var id: Int
  
  public init(periods: [PeriodBarContent], id: Int) {
    self.periods = periods
    self.id = id
  }
}

public struct PeriodBarContent: Equatable, Identifiable {
  let percentage: Double
  let fillColor: Color
  let isGlowing: Bool
  let isPulsing: Bool
  public let id: Int
  
  public init(percentage: Double, fillColor: Color, isGlowing: Bool, isPulsing: Bool, id: Int) {
    self.percentage = percentage
    self.fillColor = fillColor
    self.isGlowing = isGlowing
    self.isPulsing = isPulsing
    self.id = id
  }
}

public struct PeriodBars: View {
  
  @ObservedObject var sessions: ViewStore<[SessionViewContent], PeriodBarAction>
    
  public init(sessions: ViewStore<[SessionViewContent], PeriodBarAction>) {
    self.sessions = sessions
  }
  
  public var body: some View {
    VStack {
    HStack(spacing: 6) {
      ForEach (sessions.state) { aSession in
        periodBars(for: aSession)
      }
    }
    }
  }
  
  func periodBars(for session: SessionViewContent) -> some View {
    HStack(spacing: 2) {
      ForEach(session.periods) { period in
        PeriodBar(content: period)
      }
    }
  }
}

//struct PeriodBar_Previews: PreviewProvider {
//  static var previews: some View {
//    PeriodBars(sessions: .constant([]))
//      .scaleEffect(0.5)
//      .frame(maxWidth: .infinity, maxHeight: .infinity)
//      .background(.black)
//    
//  }
//}


//final class PeriodBarView: UIView {
//
//  let gradientLayer = makeLinearGradient()
//
//  override init(frame: CGRect) {
//    super.init(frame: frame)
//
//    layer.addSublayer(gradientLayer)
//  }
//
//  required init?(coder: NSCoder) {
//    fatalError("init(coder:) has not been implemented")
//  }
//
//  override func layoutSubviews() {
//    super.layoutSubviews()
//
//    gradientLayer.frame = bounds
//  }
//}

//func makeLinearGradient() -> CALayer {
//  let layerGradient = CAGradientLayer()
//
//  layerGradient.colors = [UIColor.orange.cgColor, UIColor.red.cgColor]
//  layerGradient.startPoint = CGPoint(x: 0.5, y: 0.0)
//  layerGradient.endPoint = CGPoint(x: 0.5, y: 1)
//
//  layerGradient.locations = [0.0, 0.6, 1.0]
//
//  return layerGradient
//}

//struct PeriodBarViewRepresentable: UIViewRepresentable {
//  func makeUIView(context _: Context) -> UIView {
//    PeriodBarView()
//  }
//
//  func updateUIView(_: UIView, context _: Context) {}
//}

//struct PeriodBar_Previews: PreviewProvider {
//    static var previews: some View {
//        // the SwiftUI View
//      PeriodBarViewRepresentable()
//        .frame(width: 50, height: 130)
//        .cornerRadius(20)
////        .foregroundColor(.clear)
////        .background(LinearGradient(gradient: Gradient(colors: [.orange, .red]), startPoint: .top, endPoint: .bottom).cornerRadius: 16)
//    }
//}

extension View {
  func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
    clipShape( RoundedCorner(radius: radius, corners: corners) )
  }
}

struct RoundedCorner: Shape {
  var radius: CGFloat = .infinity
  var corners: UIRectCorner = .allCorners
  
  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
    return Path(path.cgPath)
  }
}

