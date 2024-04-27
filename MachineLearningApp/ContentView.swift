//
//  ContentView.swift
//  MachineLearningApp
//
//  Created by Davide Castaldi on 27/04/24.
//

import CoreML
import SwiftUI

/*
 Simply put. Machine learning is more about how you train the machine rather than how you use the data. First we need to create a model through CreateML (XCode -> dev tools -> CreateML). Create a new document and select one of the different types. They are:
 
 Image, multilaber, object, style, hand pose, action, hand action, activity, sound, text, word tagging, tabular classification, tabular regression, recommendation.

 For this project a tabular regression is used because it predicts the numeric value of a feature, given other feature's values. Features are represented as columns in tabular data.
 
 After naming, we go to Training Data and select a .csv file that contains all the data we need. Then, after selecting, choose the feature and then the target that is used for CoreML, along with the features that are the things CoreML is going to use. There is a multiple selection so we can decide which to use, click train and we are done. Another thing is that we can use different algorithms. Testing can be done in testing tab, and in evaluation we can understand the root mean square error, which is the margin distance that our trained model has to give incorrect inforation. In this case we are going to have almost 3 minutes of margin error which is quite acceptable in our case. Different training can be done to get different outcomes, by simply duplicating and repeating the process.
 */
struct ContentView: View {
    
    //first declare the values to use
    @State private var wakeUp = defaultWakeTime
    @State private var sleepAmount = 8.0
    @State private var coffeeAmount = 1
    
    //this is for the alert message
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false

    //for UX purposes, when selecting the time it is common to start at a possible default one, 7 AM
    static var defaultWakeTime: Date {
        //get the components (date, hours, minutes etc...)
        var components = DateComponents()
        
        //set the values
        components.hour = 7
        components.minute = 0
        
        //return the actual date and define a possible default value otherwise
        return Calendar.current.date(from: components) ?? .now
    }

    var body: some View {
        NavigationStack {
            //by doing form, every UI element gets separated from the horizontal line. To avoid doing so and having something divided by section, use a VStack
            Form {
                VStack(alignment: .leading, spacing: 0) {
                    Text("When do you want to wake up?")
                        .font(.headline)
                    
                    //this is the common way to use a datepicker
                    DatePicker("Please enter a time", selection: $wakeUp, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text("Desired amount of sleep")
                        .font(.headline)
                    
                    //the stepper is the button that increments or decrements. Here we decide for how much
                    Stepper("\(sleepAmount.formatted()) hours", value: $sleepAmount, in: 4...12, step: 0.25)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text("Daily coffee intake")
                        .font(.headline)
                    
                    //this is one beautiful way to simply tell swift that if coffee amount is one, use the singular, otherwise plural. Swift checks the value and uses that
                    Stepper("^[\(coffeeAmount) cup](inflect: true)", value: $coffeeAmount, in: 1...20)
                }
            }
            .navigationTitle("BetterRest")
            .toolbar {
                Button("Calculate", action: calculateBedtime)
            }
            //this is how alerts are made. The bool becomes false once the button is pressed automatically
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    func calculateBedtime() {
        do {
            //first define the model (config) and extract it into a model.
            let config = MLModelConfiguration()
            let model = try SleepCalculator(configuration: config)

            //then define the components from the calendar to use
            let components = Calendar.current.dateComponents([.hour, .minute], from: wakeUp)
            //define the hours with the math formula, and the minutes
            let hour = (components.hour ?? 0) * 60 * 60
            let minute = (components.minute ?? 0) * 60

            //the prediction is extracted through the model and the data.
            let prediction = try model.prediction(wake: Double(hour + minute), estimatedSleep: sleepAmount, coffee: Double(coffeeAmount))

            //and the output is basically this
            let sleepTime = wakeUp - prediction.actualSleep

            //this shows the output
            alertTitle = "Your ideal bedtime is"
            alertMessage = sleepTime.formatted(date: .omitted, time: .shortened)
        } catch {
            //if something goes wrong, the alert message changes
            alertTitle = "Error"
            alertMessage = "Sorry, there was a problem calculating your bedtime."
        }
        //no matter the result, the alert always pops up
        showingAlert = true
    }
}

#Preview {
    ContentView()
}
