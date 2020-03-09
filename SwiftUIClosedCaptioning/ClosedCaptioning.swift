//
//  ClosedCaptioning.swift
//  SwiftUIClosedCaptioning
//
//  Created by Daniel Bolella on 9/30/19.
//  Copyright © 2019 Daniel Bolella. All rights reserved.
//

import Foundation
import Speech
import FirebaseMLNLTranslate

class ClosedCaptioning: VideoMediaInputDelegate, ObservableObject {
    func videoFrameRefresh(sampleBuffer: CMSampleBuffer) {
        recognitionRequest?.appendAudioSampleBuffer(sampleBuffer)
    }
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private let translator: Translator
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    @Published var captioning: String = ""
    
    init() {
        let options = TranslatorOptions(sourceLanguage: .en, targetLanguage: .it)
        translator = NaturalLanguage.naturalLanguage().translator(options: options)
        translator.downloadModelIfNeeded { (error) in
          guard error == nil else { return }
        }
        setupRecognition()
    }
    
    private func setupRecognition() {
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        // we want to get continuous recognition and not everything at once at the end of the video
        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            if(result != nil){
                self!.translator.translate(result!.bestTranscription.formattedString) { (translatedText, error) in
                  guard error == nil,
                    let translatedText = translatedText
                    else { return }
                  self?.captioning = translatedText
                }
            }

            // if connected to internet, then once in about every minute recognition task finishes
            // so we need to set up a new one to continue recognition
            if result?.isFinal == true {
                self?.recognitionRequest = nil
                self?.recognitionTask = nil

                self?.setupRecognition()
            }
        }
        self.recognitionRequest = recognitionRequest
    }
}
