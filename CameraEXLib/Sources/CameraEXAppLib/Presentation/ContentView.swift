//
//  File.swift
//  
//  
//  Created by fuziki on 2023/05/07
//  
//

import SwiftUI

public struct ContentView: View {
    @ObservedObject var vm = ContentViewModel()

    public init() {}

    public var body: some View {
        VStack {
            HStack {
                Button {
                    vm.activate()
                } label: {
                    Text("activate")
                }
                Button {
                    vm.deactivate()
                } label: {
                    Text("deactivate")
                }
            }
            Text(vm.state)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
