"""
Module for interacting with the YouTube API.
"""

import os
import logging
import yt_dlp
import webvtt

from urllib.parse import urlparse, parse_qs
from isodate import parse_duration
from googleapiclient.discovery import build
from client.secrets_manager_client import SecretsManagerClient

logging.getLogger().setLevel(logging.INFO)

CHANNEL_NAME = os.environ.get("YOUTUBE_CHANNEL_NAME")


class YouTubeClient:  # pylint: disable=no-member, broad-exception-raised
    """
    Class for interacting with the YouTube API.
    """

    def __init__(self):
        self.youtube_client = self._create_authenticated_client()

    def get_video_id(self, video_url):
        """
        Get the ID of the latest video in the channel.
        """
        # Parse the URL
        parsed_url = urlparse(video_url)

        # Check if it's a YouTube URL.
        if "youtube.com" in parsed_url.netloc:
            video_id = parse_qs(parsed_url.query).get("v", [None])[0]
        elif "youtu.be" in parsed_url.netloc:
            parsed_url = urlparse(video_url)
            path = parsed_url.path
            video_id = path.strip("/").split("/")[0]  # Extract video ID
        else:
            raise Exception("Invalid YouTube URL.")

        response = (
            self.youtube_client.videos()
            .list(part="contentDetails", id=video_id)
            .execute()
        )

        # Get the duration of the video and check if it's less than 60 seconds
        duration = response["items"][0]["contentDetails"]["duration"]
        duration_seconds = parse_duration(duration).total_seconds()
        if duration_seconds < 60:
            return video_id, True
        return video_id, False

    def get_video_transcript(self, url, max_line_width=80):
        """
        Get the transcript of the latest video in the channel.
        """
        ydl_opts = {
            "writeautomaticsub": True,  # Download auto-generated subtitles
            "subtitleslangs": ["en"],  # Download subtitles in English
            "skip_download": True,  # Skip video download
            "outtmpl": "/tmp/temp-sub.%(ext)s",
        }

        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([url])

        # Path to your .vtt subtitle file
        vtt_file = "/tmp/temp-sub.en.vtt"

        # List to store the extracted words
        subtitle_text = []

        # Parse the .vtt file and extract the text only
        for caption in webvtt.read(vtt_file):
            subtitle_text.append(caption.text)

        # Join all the subtitle text into one block of text
        cleaned_subtitles = "\n".join(subtitle_text)

        return cleaned_subtitles

    def _create_authenticated_client(self):
        """
        Create an authenticated YouTube API client.
        """
        secret_id = os.environ.get("YOUTUBE_TOKEN_ID")
        api_key = SecretsManagerClient().get_secret(secret_id)
        return build("youtube", "v3", developerKey=api_key)
