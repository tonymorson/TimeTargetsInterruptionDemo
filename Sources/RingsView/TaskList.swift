//
//  SwiftUIView.swift
//  
//
//  Created by Anthony Morson on 1/16/22.
//

import SwiftUI

public struct TaskList: View {
  
  @State var items: [String] = [
    "Task 1",
    "Task 2",
    "Task 3",
    "Task 4",
    "Task 5",
  ]
  
  @State var selection: Int = 2
  
  public init () {}
  
  public var body: some View {
    VStack {
      
//      Picker("", selection: $selection) {
//        Text("Today").tag(0)
//        Text("Yesterday").tag(1)
//        Text("History").tag(2)
//      }.pickerStyle(.segmented)
//        .padding(.horizontal)

      Form {
        
        Section {
          List(["Current Item"], id: \.self) { item in
             Text(item)
           }
        } header: {
          HStack {
            Text("Now")
            Spacer()
            Button {
              
            } label: {
//              Image(systemName: "plus.circle.fill")
//                .font(.title2)
//                .offset(x: 10, y: -0)

              Text("Mark Done")
                .foregroundColor(.red)
            }

          }
        }

        
        Section {
          List(items, id: \.self) { item in
             Text(item)
           }
        } header: {
          HStack {
            Text("Coming Up")
            Spacer()
            Button {
              
            } label: {
              Image(systemName: "plus.circle.fill")
                .font(.title2)
                .offset(x: 10, y: -0)
//
//              Text("+")
                .foregroundColor(.red)
            }

          }
        }

        Section {
          List(items, id: \.self) { item in
             Text(item)
           }
        } header: {
          HStack {
            Text("Recent History")
            Spacer()
            Button {
              
            } label: {
              Text("Show more")
                .foregroundColor(.red)
//              Image(systemName: "plus.circle.fill")
//                .font(.title2)
//                .offset(x: 10, y: -0)
            }

          }
        }
        
        
        
//        Section("Inventory") {
//          List(items, id: \.self) { item in
//            Text(item)
//          }
//        }
      }
    }
  }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        TaskList()
    }
}
