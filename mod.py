import os
import io
import numpy as np
import pandas as pd
import librosa
import soundfile as sf
import traceback
import tempfile
from flask import Flask, request, jsonify
from keras.models import load_model
import matplotlib.pyplot as plt
from pydub import AudioSegment  # NEW: For AAC to WAV conversion

app = Flask(__name__)

# Function to extract MFCC features from audio data
def extract_mfcc(y, sr):
    """Extract MFCC features from audio data"""
    mfcc = np.mean(librosa.feature.mfcc(y=y, sr=sr, n_mfcc=40).T, axis=0)
    return mfcc

# Function to analyze audio data by splitting into segments and detecting emotions
def analyze_long_audio(audio_data, sr, model_path, window_size=3, hop_length=1.5):
    """Analyze audio by detecting emotions for each segment"""
    duration = librosa.get_duration(y=audio_data, sr=sr)
    model = load_model(model_path)
    emotions = ['angry', 'sad', 'fear', 'neutral', 'ps', 'happy', 'disgust']
    results = []
    start_times = np.arange(0, duration - window_size, hop_length)

    for start in start_times:
        end = start + window_size
        segment = audio_data[int(start * sr):int(end * sr)]
        features = extract_mfcc(segment, sr)
        features = np.expand_dims(features, axis=[0, -1])

        predictions = model.predict(features, verbose=0)
        emotion_scores = predictions[0]
        primary_emotion = emotions[np.argmax(emotion_scores)]
        confidence = np.max(emotion_scores)

        results.append({
            'start_time': start,
            'end_time': end,
            'primary_emotion': primary_emotion,
            'confidence': float(confidence),
            **{emotions[i]: float(emotion_scores[i]) for i in range(len(emotions))}
        })

    return pd.DataFrame(results)

# Function to generate emotional summary
def get_emotional_summary(results_df):
    """Generate a summary of the emotional content."""
    if results_df.empty:
        return "No emotions detected in the audio."

    total_duration = results_df['end_time'].max() - results_df['start_time'].min()
    emotion_counts = results_df['primary_emotion'].value_counts()
    emotion_duration = {}

    for emotion in emotion_counts.index:
        segments_with_emotion = results_df[results_df['primary_emotion'] == emotion]
        duration = (segments_with_emotion['end_time'] - segments_with_emotion['start_time']).sum()
        percentage = (duration / total_duration) * 100
        emotion_duration[emotion] = (duration, percentage)

    transitions = []
    prev_emotion = None
    for _, row in results_df.iterrows():
        if prev_emotion is not None and row['primary_emotion'] != prev_emotion:
            transitions.append((prev_emotion, row['primary_emotion'], row['start_time']))
        prev_emotion = row['primary_emotion']

    summary = f"EMOTIONAL ANALYSIS SUMMARY:\n"
    summary += f"Total audio duration: {total_duration:.2f} seconds\n\n"
    summary += "Emotion distribution:\n"
    for emotion, (duration, percentage) in emotion_duration.items():
        summary += f"  {emotion}: {duration:.2f}\n"

    if not emotion_counts.empty:
        dominant_emotion = emotion_counts.index[0]
        summary += f"\nDominant emotion: {dominant_emotion}\n\n"

    summary += "Emotional transitions:\n"
    if transitions:
        for from_emotion, to_emotion, time in transitions:
            summary += f"  {from_emotion} → {to_emotion} at {time:.2f}s\n"
    else:
        summary += "  No emotional transitions detected\n"

    return summary
# API endpoint
@app.route('/analyze', methods=['POST'])
def analyze_audio():
    """Endpoint to analyze emotion in an audio file"""
    print("Request received")
    if 'audio' not in request.files:
        return jsonify({'error': 'No audio file provided'}), 400

    audio_file = request.files['audio']
    model_path = 'model.h5'  # Adjust this to your model location

    try:
        # Read the audio file
        audio_bytes = audio_file.read()

        # Save AAC temporarily
        with tempfile.NamedTemporaryFile(suffix=".aac", delete=False) as temp_aac:
            temp_aac.write(audio_bytes)
            temp_aac.flush()
            temp_aac_path = temp_aac.name

        # Convert AAC to WAV
        try:
            audio = AudioSegment.from_file(temp_aac_path, format="aac")
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as temp_wav:
                audio.export(temp_wav.name, format="wav")
                wav_path = temp_wav.name

            # Load WAV with librosa
            audio_data, sr = librosa.load(wav_path, sr=None)

        finally:
            os.remove(temp_aac_path)
            if os.path.exists(wav_path):
                os.remove(wav_path)

        print(f"Audio loaded successfully. Duration: {librosa.get_duration(y=audio_data, sr=sr):.2f}s, Sample rate: {sr}Hz")

        # Analyze
        results_df = analyze_long_audio(audio_data, sr, model_path, window_size=3, hop_length=1)
        summary = get_emotional_summary(results_df)
        print(summary)

        # Response
        return jsonify({
            'results': results_df.to_dict(orient='records'),
            'summary': summary
        })

    except Exception as e:
        print(f"Error processing audio: {str(e)}")
        print(traceback.format_exc())
        return jsonify({'error': f'Error processing audio: {str(e)}'}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)

















# import os
# import io
# import numpy as np
# import pandas as pd
# import librosa
# import soundfile as sf
# import traceback
# from flask import Flask, request, jsonify
# from keras.models import load_model
# import matplotlib.pyplot as plt
#
# app = Flask(__name__)
#
# # Function to extract MFCC features from audio data
# def extract_mfcc(y, sr):
#     """Extract MFCC features from audio data"""
#     mfcc = np.mean(librosa.feature.mfcc(y=y, sr=sr, n_mfcc=40).T, axis=0)
#     return mfcc
#
# # Function to analyze audio data by splitting into segments and detecting emotions
# def analyze_long_audio(audio_data, sr, model_path, window_size=3, hop_length=1.5):
#     """Analyze audio by detecting emotions for each segment"""
#     duration = librosa.get_duration(y=audio_data, sr=sr)
#     model = load_model(model_path)
#     emotions = ['angry', 'sad', 'fear', 'neutral', 'ps', 'happy', 'disgust']
#     results = []
#     start_times = np.arange(0, duration - window_size, hop_length)
#
#     for i, start in enumerate(start_times):
#         end = start + window_size
#         segment = audio_data[int(start * sr):int(end * sr)]
#         features = extract_mfcc(segment, sr)
#         features = np.expand_dims(features, axis=[0, -1])
#
#         predictions = model.predict(features, verbose=0)
#         emotion_scores = predictions[0]
#         primary_emotion = emotions[np.argmax(emotion_scores)]
#         confidence = np.max(emotion_scores)
#
#         results.append({
#             'start_time': start,
#             'end_time': end,
#             'primary_emotion': primary_emotion,
#             'confidence': float(confidence),
#             **{emotions[i]: float(emotion_scores[i]) for i in range(len(emotions))}
#         })
#
#     return pd.DataFrame(results)
#
# # Function to generate emotional summary
# def get_emotional_summary(results_df):
#     """Generate a summary of the emotional content."""
#     if results_df.empty:
#         return "No emotions detected in the audio."
#
#     total_duration = results_df['end_time'].max() - results_df['start_time'].min()
#     emotion_counts = results_df['primary_emotion'].value_counts()
#     emotion_duration = {}
#
#     for emotion in emotion_counts.index:
#         segments_with_emotion = results_df[results_df['primary_emotion'] == emotion]
#         duration = (segments_with_emotion['end_time'] - segments_with_emotion['start_time']).sum()
#         percentage = (duration / total_duration) * 100
#         emotion_duration[emotion] = (duration, percentage)
#
#     transitions = []
#     prev_emotion = None
#     for i, row in results_df.iterrows():
#         if prev_emotion is not None and row['primary_emotion'] != prev_emotion:
#             transitions.append((prev_emotion, row['primary_emotion'], row['start_time']))
#         prev_emotion = row['primary_emotion']
#
#     summary = f"EMOTIONAL ANALYSIS SUMMARY:\n"
#     summary += f"Total audio duration: {total_duration:.2f} seconds\n\n"
#     summary += "Emotion distribution:\n"
#     for emotion, (duration, percentage) in emotion_duration.items():
#         summary += f"  {emotion}: {duration:.2f}s ({percentage:.1f}%)\n"
#
#     if not emotion_counts.empty:
#         dominant_emotion = emotion_counts.index[0]
#         summary += f"\nDominant emotion: {dominant_emotion}\n\n"
#
#     summary += "Emotional transitions:\n"
#     if transitions:
#         for from_emotion, to_emotion, time in transitions:
#             summary += f"  {from_emotion} → {to_emotion} at {time:.2f}s\n"
#     else:
#         summary += "  No emotional transitions detected\n"
#
#     return summary
# @app.route('/analyze', methods=['POST'])
# def analyze_audio():
#     """Endpoint to analyze emotion in audio file."""
#     print("Request received")
#     print(f"Files in request: {request.files}")
#     if 'audio' not in request.files:
#         return jsonify({'error': 'No audio file provided'}), 400
#
# # @app.route('/analyze', methods=['POST'])
# # def analyze_audio():
# #
# #     """Endpoint to analyze emotion in audio file."""
# #     if 'audio' not in request.files:
# #         return jsonify({'error': 'No audio file provided'}), 400
#
#     audio_file = request.files['audio']
#     model_path = 'model.h5'  # Change this to your actual model path
#
#     try:
#         # Read the audio data directly from the uploaded file
#         audio_bytes = audio_file.read()
#         audio_buffer = io.BytesIO(audio_bytes)
#
#         # Load audio using librosa
#         try:
#             audio_data, sr = librosa.load(audio_buffer, sr=None)
#         except Exception as e:
#             return jsonify({'error': f'Error loading audio: {str(e)}'}), 400
#
#         print(f"Audio loaded successfully. Duration: {librosa.get_duration(y=audio_data, sr=sr):.2f}s, Sample rate: {sr}Hz")
#
#         # Analyze the audio data
#         results_df = analyze_long_audio(audio_data, sr, model_path, window_size=3, hop_length=1)
#
#         # Generate summary
#         summary = get_emotional_summary(results_df)
#         print(summary)  # Print to server logs
#
#         # Return results
#         return jsonify({
#             'results': results_df.to_dict(orient='records'),
#             'summary': summary
#         })
#
#     except Exception as e:
#         print(f"Error processing audio: {str(e)}")
#         print(traceback.format_exc())  # Print the full stack trace for more insights
#         return jsonify({'error': f'Error processing audio: {str(e)}'}), 500
#
# if __name__ == "__main__":
#     app.run(host="0.0.0.0", port=5000, debug=True)
#















# works normally
# import os
# import io
# import numpy as np
# import pandas as pd
# import librosa
# import soundfile as sf
# import traceback
# from flask import Flask, request, jsonify
# from keras.models import load_model
# import matplotlib.pyplot as plt
#
# app = Flask(__name__)
#
# # Function to extract MFCC features from audio data
# def extract_mfcc(y, sr):
#     """Extract MFCC features from audio data"""
#     mfcc = np.mean(librosa.feature.mfcc(y=y, sr=sr, n_mfcc=40).T, axis=0)
#     return mfcc
#
# # Function to analyze audio data by splitting into segments and detecting emotions
# def analyze_long_audio(audio_data, sr, model_path, window_size=3, hop_length=1.5):
#     """Analyze audio by detecting emotions for each segment"""
#     duration = librosa.get_duration(y=audio_data, sr=sr)
#     model = load_model(model_path)
#     emotions = ['angry', 'sad', 'fear', 'neutral', 'ps', 'happy', 'disgust']
#     results = []
#     start_times = np.arange(0, duration - window_size, hop_length)
#
#     for i, start in enumerate(start_times):
#         end = start + window_size
#         segment = audio_data[int(start * sr):int(end * sr)]
#         features = extract_mfcc(segment, sr)
#         features = np.expand_dims(features, axis=[0, -1])
#
#         predictions = model.predict(features, verbose=0)
#         emotion_scores = predictions[0]
#         primary_emotion = emotions[np.argmax(emotion_scores)]
#         confidence = np.max(emotion_scores)
#
#         results.append({
#             'start_time': start,
#             'end_time': end,
#             'primary_emotion': primary_emotion,
#             'confidence': float(confidence),
#             **{emotions[i]: float(emotion_scores[i]) for i in range(len(emotions))}
#         })
#
#     return pd.DataFrame(results)
#
# # Function to generate emotional summary
# def get_emotional_summary(results_df):
#     """Generate a summary of the emotional content."""
#     if results_df.empty:
#         return "No emotions detected in the audio."
#
#     total_duration = results_df['end_time'].max() - results_df['start_time'].min()
#     emotion_counts = results_df['primary_emotion'].value_counts()
#     emotion_duration = {}
#
#     for emotion in emotion_counts.index:
#         segments_with_emotion = results_df[results_df['primary_emotion'] == emotion]
#         duration = (segments_with_emotion['end_time'] - segments_with_emotion['start_time']).sum()
#         percentage = (duration / total_duration) * 100
#         emotion_duration[emotion] = (duration, percentage)
#
#     transitions = []
#     prev_emotion = None
#     for i, row in results_df.iterrows():
#         if prev_emotion is not None and row['primary_emotion'] != prev_emotion:
#             transitions.append((prev_emotion, row['primary_emotion'], row['start_time']))
#         prev_emotion = row['primary_emotion']
#
#     summary = f"EMOTIONAL ANALYSIS SUMMARY:\n"
#     summary += f"Total audio duration: {total_duration:.2f} seconds\n\n"
#     summary += "Emotion distribution:\n"
#     for emotion, (duration, percentage) in emotion_duration.items():
#         summary += f"  {emotion}: {duration:.2f}s ({percentage:.1f}%)\n"
#
#     if not emotion_counts.empty:
#         dominant_emotion = emotion_counts.index[0]
#         summary += f"\nDominant emotion: {dominant_emotion}\n\n"
#
#     summary += "Emotional transitions:\n"
#     if transitions:
#         for from_emotion, to_emotion, time in transitions:
#             summary += f"  {from_emotion} → {to_emotion} at {time:.2f}s\n"
#     else:
#         summary += "  No emotional transitions detected\n"
#
#     return summary
#
# @app.route('/analyze', methods=['POST'])
# def analyze_audio():
#     """Endpoint to analyze emotion in audio file."""
#     if 'audio' not in request.files:
#         return jsonify({'error': 'No audio file provided'}), 400
#
#     audio_file = request.files['audio']
#     model_path = 'model.h5'  # Change this to your actual model path
#
#     try:
#         # Read the audio data directly from the uploaded file
#         audio_bytes = audio_file.read()
#         audio_buffer = io.BytesIO(audio_bytes)
#
#         # Load audio using librosa
#         try:
#             audio_data, sr = librosa.load(audio_buffer, sr=None)
#         except Exception as e:
#             return jsonify({'error': f'Error loading audio: {str(e)}'}), 400
#
#         print(f"Audio loaded successfully. Duration: {librosa.get_duration(y=audio_data, sr=sr):.2f}s, Sample rate: {sr}Hz")
#
#         # Analyze the audio data
#         results_df = analyze_long_audio(audio_data, sr, model_path, window_size=3, hop_length=1)
#
#         # Generate summary
#         summary = get_emotional_summary(results_df)
#         print(summary)  # Print to server logs
#
#         # Return results
#         return jsonify({
#             'results': results_df.to_dict(orient='records'),
#             'summary': summary
#         })
#
#     except Exception as e:
#         print(f"Error processing audio: {str(e)}")
#         print(traceback.format_exc())  # Print the full stack trace for more insights
#         return jsonify({'error': f'Error processing audio: {str(e)}'}), 500
#
# if __name__ == "__main__":
#     app.run(host="0.0.0.0", port=5000, debug=True)
#





# import os
# import io
# import numpy as np
# import pandas as pd
# import librosa
# import soundfile as sf
# import traceback
# from flask import Flask, request, jsonify
# from keras.models import load_model
# import matplotlib.pyplot as plt
#
# app = Flask(__name__)
#
# # Function to extract MFCC features from audio data
# def extract_mfcc(y, sr):
#     """Extract MFCC features from audio data"""
#     mfcc = np.mean(librosa.feature.mfcc(y=y, sr=sr, n_mfcc=40).T, axis=0)
#     return mfcc
#
# # Function to analyze audio data by splitting into segments and detecting emotions
# def analyze_long_audio(audio_data, sr, model_path, window_size=3, hop_length=1.5):
#     """
#     Analyze audio data by breaking it into segments and detecting emotions in each.
#
#     Parameters:
#     - audio_data: numpy array of audio samples
#     - sr: sample rate
#     - model_path: path to the emotion recognition model
#     - window_size: size of each segment in seconds
#     - hop_length: how much to move forward between segments
#     """
#     # Get audio duration
#     duration = librosa.get_duration(y=audio_data, sr=sr)
#
#     # Load the model
#     model = load_model(model_path)
#
#     # Define emotion classes (must match your model's training order)
#     emotions = ['angry', 'sad', 'fear', 'neutral', 'ps', 'happy', 'disgust']
#
#     # Process segments
#     results = []
#     start_times = np.arange(0, duration - window_size, hop_length)
#
#     print(f"Processing {len(start_times)} segments...")
#
#     for i, start in enumerate(start_times):
#         if i % 10 == 0:  # Progress update
#             print(f"Processing segment {i+1}/{len(start_times)}")
#
#         # Extract segment
#         end = start + window_size
#         segment = audio_data[int(start * sr):int(end * sr)]
#
#         # Extract features
#         features = extract_mfcc(segment, sr)
#         features = np.expand_dims(features, axis=[0, -1])  # Reshape for LSTM input
#
#         # Predict emotion
#         predictions = model.predict(features, verbose=0)
#         emotion_scores = predictions[0]
#         primary_emotion = emotions[np.argmax(emotion_scores)]
#         confidence = np.max(emotion_scores)
#
#         # Store results
#         results.append({
#             'start_time': start,
#             'end_time': end,
#             'primary_emotion': primary_emotion,
#             'confidence': float(confidence),  # Convert numpy types to native Python for JSON serialization
#             **{emotions[i]: float(emotion_scores[i]) for i in range(len(emotions))}
#         })
#
#     # Convert to DataFrame
#     results_df = pd.DataFrame(results)
#     return results_df
#
# # Function to generate emotional summary
# def get_emotional_summary(results_df):
#     """Generate a summary of the emotional content."""
#     if results_df.empty:
#         return "No emotions detected in the audio."
#
#     total_duration = results_df['end_time'].max() - results_df['start_time'].min()
#
#     # Count time spent in each emotion
#     emotion_counts = results_df['primary_emotion'].value_counts()
#     emotion_duration = {}
#
#     # Calculate duration spent in each emotion
#     for emotion in emotion_counts.index:
#         segments_with_emotion = results_df[results_df['primary_emotion'] == emotion]
#         # Sum the durations where this emotion was primary
#         duration = (segments_with_emotion['end_time'] - segments_with_emotion['start_time']).sum()
#         percentage = (duration / total_duration) * 100
#         emotion_duration[emotion] = (duration, percentage)
#
#     # Find emotional transitions
#     transitions = []
#     prev_emotion = None
#     for i, row in results_df.iterrows():
#         if prev_emotion is not None and row['primary_emotion'] != prev_emotion:
#             transitions.append((prev_emotion, row['primary_emotion'], row['start_time']))
#         prev_emotion = row['primary_emotion']
#
#     # Format the output summary
#     summary = f"EMOTIONAL ANALYSIS SUMMARY:\n"
#     summary += f"Total audio duration: {total_duration:.2f} seconds\n\n"
#
#     summary += "Emotion distribution:\n"
#     for emotion, (duration, percentage) in emotion_duration.items():
#         summary += f"  {emotion}: {duration:.2f}s ({percentage:.1f}%)\n"
#
#     if not emotion_counts.empty:
#         dominant_emotion = emotion_counts.index[0]
#         summary += f"\nDominant emotion: {dominant_emotion}\n\n"
#
#     summary += "Emotional transitions:\n"
#     if transitions:
#         for from_emotion, to_emotion, time in transitions:
#             summary += f"  {from_emotion} → {to_emotion} at {time:.2f}s\n"
#     else:
#         summary += "  No emotional transitions detected\n"
#
#     return summary
#
# @app.route('/analyze', methods=['POST'])
# def analyze_audio():
#     """Endpoint to analyze emotion in audio file."""
#     if 'audio' not in request.files:
#         return jsonify({'error': 'No audio file provided'}), 400
#
#     audio_file = request.files['audio']
#     model_path = 'model.h5'  # Change this to your actual model path
#
#     try:
#         # Read the audio data directly from the uploaded file
#         audio_bytes = audio_file.read()
#         audio_buffer = io.BytesIO(audio_bytes)
#
#         # Load audio using librosa, it automatically handles different formats
#         audio_data, sr = librosa.load(audio_buffer, sr=None)  # `sr=None` ensures it uses the original sample rate
#
#         print(f"Audio loaded successfully. Duration: {librosa.get_duration(y=audio_data, sr=sr):.2f}s, Sample rate: {sr}Hz")
#
#         # Analyze the audio data
#         results_df = analyze_long_audio(audio_data, sr, model_path, window_size=3, hop_length=1)
#
#         # Generate summary
#         summary = get_emotional_summary(results_df)
#         print(summary)  # Print to server logs
#
#         # Return results
#         return jsonify({
#             'results': results_df.to_dict(orient='records'),
#             'summary': summary
#         })
#
#     except Exception as e:
#         print(f"Error processing audio: {str(e)}")
#         print(traceback.format_exc())  # Print the full stack trace for more insights
#         return jsonify({'error': f'Error processing audio: {str(e)}'}), 500
#
# if __name__ == "__main__":
#     app.run(host="0.0.0.0", port=5000, debug=True)
#



# from flask import Flask, request, jsonify
# import os
# import librosa
# import numpy as np
# import pandas as pd
# import matplotlib.pyplot as plt
# from keras.models import load_model
# import time
# import io
# import soundfile as sf
#
# app = Flask(__name__)
#
# # Function to extract MFCC features from audio data
# def extract_mfcc(y, sr):
#     """Extract MFCC features from audio data"""
#     mfcc = np.mean(librosa.feature.mfcc(y=y, sr=sr, n_mfcc=40).T, axis=0)
#     return mfcc
#
# # Function to analyze audio data by splitting into segments and detecting emotions
# def analyze_long_audio(audio_data, sr, model_path, window_size=3, hop_length=1.5):
#     """
#     Analyze audio data by breaking it into segments and detecting emotions in each.
#
#     Parameters:
#     - audio_data: numpy array of audio samples
#     - sr: sample rate
#     - model_path: path to the emotion recognition model
#     - window_size: size of each segment in seconds
#     - hop_length: how much to move forward between segments
#     """
#     # Get audio duration
#     duration = librosa.get_duration(y=audio_data, sr=sr)
#
#     # Load the model
#     model = load_model(model_path)
#
#     # Define emotion classes (must match your model's training order)
#     emotions = ['angry', 'sad', 'fear', 'neutral', 'ps', 'happy', 'disgust']
#
#     # Process segments
#     results = []
#     start_times = np.arange(0, duration - window_size, hop_length)
#
#     print(f"Processing {len(start_times)} segments...")
#
#     for i, start in enumerate(start_times):
#         if i % 10 == 0:  # Progress update
#             print(f"Processing segment {i+1}/{len(start_times)}")
#
#         # Extract segment
#         end = start + window_size
#         segment = audio_data[int(start * sr):int(end * sr)]
#
#         # Extract features
#         features = extract_mfcc(segment, sr)
#         features = np.expand_dims(features, axis=[0, -1])  # Reshape for LSTM input
#
#         # Predict emotion
#         predictions = model.predict(features, verbose=0)
#         emotion_scores = predictions[0]
#         primary_emotion = emotions[np.argmax(emotion_scores)]
#         confidence = np.max(emotion_scores)
#
#         # Store results
#         results.append({
#             'start_time': start,
#             'end_time': end,
#             'primary_emotion': primary_emotion,
#             'confidence': float(confidence),  # Convert numpy types to native Python for JSON serialization
#             **{emotions[i]: float(emotion_scores[i]) for i in range(len(emotions))}
#         })
#
#     # Convert to DataFrame
#     results_df = pd.DataFrame(results)
#     return results_df
#
# # Function to get emotion color
# def get_emotion_color(emotion):
#     """Return a color for each emotion type"""
#     colors = {
#         'angry': 'red',
#         'sad': 'blue',
#         'fear': 'purple',
#         'neutral': 'gray',
#         'ps': 'orange',  # assuming "ps" is "pleasant surprise"
#         'happy': 'green',
#         'disgust': 'brown'
#     }
#     return colors.get(emotion, 'black')
#
# # Function to generate emotional summary
# def get_emotional_summary(results_df):
#     """Generate a summary of the emotional content."""
#     if results_df.empty:
#         return "No emotions detected in the audio."
#
#     total_duration = results_df['end_time'].max() - results_df['start_time'].min()
#
#     # Count time spent in each emotion
#     emotion_counts = results_df['primary_emotion'].value_counts()
#     emotion_duration = {}
#
#     # Calculate duration spent in each emotion
#     for emotion in emotion_counts.index:
#         segments_with_emotion = results_df[results_df['primary_emotion'] == emotion]
#         # Sum the durations where this emotion was primary
#         duration = (segments_with_emotion['end_time'] - segments_with_emotion['start_time']).sum()
#         percentage = (duration / total_duration) * 100
#         emotion_duration[emotion] = (duration, percentage)
#
#     # Find emotional transitions
#     transitions = []
#     prev_emotion = None
#     for i, row in results_df.iterrows():
#         if prev_emotion is not None and row['primary_emotion'] != prev_emotion:
#             transitions.append((prev_emotion, row['primary_emotion'], row['start_time']))
#         prev_emotion = row['primary_emotion']
#
#     # Format the output summary
#     summary = f"EMOTIONAL ANALYSIS SUMMARY:\n"
#     summary += f"Total audio duration: {total_duration:.2f} seconds\n\n"
#
#     summary += "Emotion distribution:\n"
#     for emotion, (duration, percentage) in emotion_duration.items():
#         summary += f"  {emotion}: {duration:.2f}s ({percentage:.1f}%)\n"
#
#     if not emotion_counts.empty:
#         dominant_emotion = emotion_counts.index[0]
#         summary += f"\nDominant emotion: {dominant_emotion}\n\n"
#
#     summary += "Emotional transitions:\n"
#     if transitions:
#         for from_emotion, to_emotion, time in transitions:
#             summary += f"  {from_emotion} → {to_emotion} at {time:.2f}s\n"
#     else:
#         summary += "  No emotional transitions detected\n"
#
#     return summary
# #
# # @app.route('/analyze', methods=['POST'])
# # def analyze_audio():
# #     """Endpoint to analyze emotion in audio file."""
# #     if 'audio' not in request.files:
# #         return jsonify({'error': 'No audio file provided'}), 400
# #
# #     audio_file = request.files['audio']
# #     model_path = 'model.h5'  # Change this to your actual model path
# #
# #     try:
# #         # Read the audio data directly from the uploaded file
# #         audio_bytes = audio_file.read()
# #         audio_buffer = io.BytesIO(audio_bytes)
# #
# #         # Get audio data and sample rate using soundfile
# #         audio_data, sr = sf.read(audio_buffer)
# #
# #         print(f"Audio loaded successfully. Duration: {librosa.get_duration(y=audio_data, sr=sr):.2f}s, Sample rate: {sr}Hz")
# #
# #         # Save a copy of the file for reference/debugging (optional)
# #         temp_file_path = 'temp_received_audio.wav'
# #         sf.write(temp_file_path, audio_data, sr)
# #         print(f"Saved a copy of the audio to {temp_file_path}")
# #
# #         # Analyze the audio data
# #         results_df = analyze_long_audio(audio_data, sr, model_path, window_size=3, hop_length=1)
# #
# #         # Generate summary
# #         summary = get_emotional_summary(results_df)
# #         print(summary)  # Print to server logs
# #
# #         # Return results
# #         return jsonify({
# #             'results': results_df.to_dict(orient='records'),
# #             'summary': summary
# #         })
# #
# #     except Exception as e:
# #         print(f"Error processing audio: {str(e)}")
# #         return jsonify({'error': f'Error processing audio: {str(e)}'}), 500
#
#
# @app.route('/analyze', methods=['POST'])
# def analyze_audio():
#     """Endpoint to analyze emotion in audio file."""
#     if 'audio' not in request.files:
#         return jsonify({'error': 'No audio file provided'}), 400
#
#     audio_file = request.files['audio']
#     model_path = 'model.h5'  # Change this to your actual model path
#
#     try:
#         # Read the audio data directly from the uploaded file
#         audio_bytes = audio_file.read()
#         audio_buffer = io.BytesIO(audio_bytes)
#
#         # Load audio using librosa, it automatically handles different formats
#         audio_data, sr = librosa.load(audio_buffer, sr=None)  # `sr=None` ensures it uses the original sample rate
#
#         print(f"Audio loaded successfully. Duration: {librosa.get_duration(y=audio_data, sr=sr):.2f}s, Sample rate: {sr}Hz")
#
#         # Analyze the audio data
#         results_df = analyze_long_audio(audio_data, sr, model_path, window_size=3, hop_length=1)
#
#         # Generate summary
#         summary = get_emotional_summary(results_df)
#         print(summary)  # Print to server logs
#
#         # Return results
#         return jsonify({
#             'results': results_df.to_dict(orient='records'),
#             'summary': summary
#         })
#
#     except Exception as e:
#         print(f"Error processing audio: {str(e)}")
#         return jsonify({'error': f'Error processing audio: {str(e)}'}), 500
#
#
# if __name__ == "__main__":
#     app.run(host="0.0.0.0", port=5000, debug=True)
#

# from flask import Flask, request, jsonify
# import os
# import librosa
# import numpy as np
# import pandas as pd
# import matplotlib.pyplot as plt
# from keras.models import load_model
# import time
# import io
# import soundfile as sf
#
#
#
# app = Flask(__name__)
#
# # Function to extract MFCC features from audio data
# def extract_mfcc(y, sr):
#     """Extract MFCC features from audio data"""
#     mfcc = np.mean(librosa.feature.mfcc(y=y, sr=sr, n_mfcc=40).T, axis=0)
#     return mfcc
#
# # Function to analyze long audio by splitting into segments and detecting emotions
# def analyze_long_audio(file_path, model_path, window_size=3, hop_length=1.5):
#     """Analyze a long audio file by breaking it into segments and detecting emotions in each."""
#     # Load the audio file
#     y, sr = librosa.load(file_path)
#     duration = librosa.get_duration(y=y, sr=sr)
#
#     # Load the model
#     model = load_model(model_path)
#
#     # Define emotion classes (must match your model's training order)
#     emotions = ['angry', 'sad', 'fear', 'neutral', 'ps', 'happy', 'disgust']
#
#     # Process segments
#     results = []
#     start_times = np.arange(0, duration - window_size, hop_length)
#
#     print(f"Processing {len(start_times)} segments...")
#
#     for i, start in enumerate(start_times):
#         if i % 10 == 0:  # Progress update
#             print(f"Processing segment {i+1}/{len(start_times)}")
#
#         # Extract segment
#         end = start + window_size
#         segment = y[int(start * sr):int(end * sr)]
#
#         # Extract features
#         features = extract_mfcc(segment, sr)
#         features = np.expand_dims(features, axis=[0, -1])  # Reshape for LSTM input
#         # Predict emotion
#         predictions = model.predict(features, verbose=0)
#         emotion_scores = predictions[0]
#         primary_emotion = emotions[np.argmax(emotion_scores)]
#         confidence = np.max(emotion_scores)
#
#         # Store results
#         results.append({
#             'start_time': start,
#             'end_time': end,
#             'primary_emotion': primary_emotion,
#             'confidence': confidence,
#             **{emotions[i]: emotion_scores[i] for i in range(len(emotions))}
#         })
#
#     # Convert to DataFrame
#     results_df = pd.DataFrame(results)
#     return results_df
#
# # Function to get emotion color
# def get_emotion_color(emotion):
#     """Return a color for each emotion type"""
#     colors = {
#         'angry': 'red',
#         'sad': 'blue',
#         'fear': 'purple',
#         'neutral': 'gray',
#         'ps': 'orange',  # assuming "ps" is "pleasant surprise"
#         'happy': 'green',
#         'disgust': 'brown'
#     }
#     return colors.get(emotion, 'black')
#
# # Function to generate emotional summary
# def get_emotional_summary(results_df):
#     """Generate a summary of the emotional content."""
#     total_duration = results_df['end_time'].max() - results_df['start_time'].min()
#
#     # Count time spent in each emotion
#     emotion_counts = results_df['primary_emotion'].value_counts()
#     emotion_duration = {}
#
#     # Calculate duration spent in each emotion
#     for emotion in emotion_counts.index:
#         segments_with_emotion = results_df[results_df['primary_emotion'] == emotion]
#         # Sum the durations where this emotion was primary
#         duration = (segments_with_emotion['end_time'] - segments_with_emotion['start_time']).sum()
#         percentage = (duration / total_duration) * 100
#         emotion_duration[emotion] = (duration, percentage)
#
#     # Find emotional transitions
#     transitions = []
#     prev_emotion = None
#     for i, row in results_df.iterrows():
#         if prev_emotion is not None and row['primary_emotion'] != prev_emotion:
#             transitions.append((prev_emotion, row['primary_emotion'], row['start_time']))
#         prev_emotion = row['primary_emotion']
#
#     # Format the output summary
#     summary = f"EMOTIONAL ANALYSIS SUMMARY:\n"
#     summary += f"Total audio duration: {total_duration:.2f} seconds\n\n"
#
#     summary += "Emotion distribution:\n"
#     for emotion, (duration, percentage) in emotion_duration.items():
#         summary += f"  {emotion}: {duration:.2f}s ({percentage:.1f}%)\n"
#
#     dominant_emotion = emotion_counts.index[0]
#     summary += f"\nDominant emotion: {dominant_emotion}\n\n"
#
#     summary += "Emotional transitions:\n"
#     for from_emotion, to_emotion, time in transitions:
#         summary += f"  {from_emotion} → {to_emotion} at {time:.2f}s\n"
#
#     return summary
#
# # # Define Flask route to process the audio
# # @app.route('/analyze', methods=['POST'])
# # def analyze_audio():
# #     """Endpoint to analyze emotion in audio file."""
# #     audio_file = request.files['audio']
# #     model_path = 'model.h5'  # Change this to your actual model path
# #
# #     # Save the file temporarily
# #     temp_file_path = 'temp_audio.wav'
# #     audio_file.save(temp_file_path)
# #
# #     # Analyze the audio
# #     print(f"Analyzing audio file: {temp_file_path}")
# #     results_df = analyze_long_audio(temp_file_path, model_path, window_size=3, hop_length=1)
# #
# #     # Generate a summary
# #     summary = get_emotional_summary(results_df)
# #
# #     # Print summary to the console (or log it)
# #     print(summary)
# #
# #     # Clean up the temporary file
# #     os.remove(temp_file_path)
# #
# #     # Return the result as JSON
# #     return jsonify({
# #         'results': results_df.to_dict(orient='records'),
# #         'summary': summary
# #     })
#
# @app.route('/analyze', methods=['POST'])
# def analyze_audio():
#     audio_file = request.files['audio']
#     model_path = 'model.h5'
#
#     # Read audio bytes
#     audio_bytes = audio_file.read()
#     audio_buffer = io.BytesIO(audio_bytes)
#
#     # Use soundfile to read (returns both y and sr)
#     y, sr = sf.read(audio_buffer)
#
#     # Analyze
#     results_df = analyze_long_audio(y, sr, model_path, window_size=3, hop_length=1)
#
#     summary = get_emotional_summary(results_df)
#
#     return jsonify({
#         'results': results_df.to_dict(orient='records'),
#         'summary': summary
#     })
#
#
#
# if __name__ == "__main__":
#     app.run(host="0.0.0.0", port=5000, debug=True)
#


# from flask import Flask, request, jsonify
# import os
# import librosa
# import numpy as np
# import pandas as pd
# from keras.models import load_model
#
# app = Flask(__name__)
#
# # Load your model once at the start
# model = load_model('model.h5')
# emotions = ['angry', 'sad', 'fear', 'neutral', 'ps', 'happy', 'disgust']
#
# def extract_mfcc(y, sr):
#     mfcc = np.mean(librosa.feature.mfcc(y=y, sr=sr, n_mfcc=40).T, axis=0)
#     return mfcc
#
# @app.route('/predict', methods=['POST'])
# def predict():
#     if 'file' not in request.files:
#         return jsonify({'error': 'No file provided'}), 400
#
#     file = request.files['file']
#     file_path = os.path.join('uploads', file.filename)
#     os.makedirs('uploads', exist_ok=True)
#     file.save(file_path)
#
#     try:
#         y, sr = librosa.load(file_path)
#         features = extract_mfcc(y, sr)
#         features = np.expand_dims(features, axis=[0, -1])
#
#         predictions = model.predict(features, verbose=0)
#         emotion_scores = predictions[0]
#         primary_emotion = emotions[np.argmax(emotion_scores)]
#         confidence = np.max(emotion_scores)
#
#
#         result = {
#             'primary_emotion': primary_emotion,
#             'confidence': float(confidence),
#             'all_emotions': {emotions[i]: float(emotion_scores[i]) for i in range(len(emotions))}
#         }
#
#         return jsonify(result)
#     except Exception as e:
#         return jsonify({'error': str(e)}), 500
#     finally:
#         os.remove(file_path)  # Clean up
#
# if __name__ == '__main__':
#     app.run(host='0.0.0.0', port=5000)
