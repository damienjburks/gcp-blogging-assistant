from youtube_transcript_api import YouTubeTranscriptApi  
import requests
import re

response = requests.get('https://raw.githubusercontent.com/proxifly/free-proxy-list/main/proxies/all/data.txt')
proxies = response.text.splitlines()

pattern = r'(https?://\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d{1,5})'

http_proxies = []
for proxy in proxies:
    match = re.search(pattern, proxy)
    if match:
        http_proxies.append(match.group(1))

for http_proxy in http_proxies:
    transcript = YouTubeTranscriptApi.get_transcript('6IW1HQD2R5g', proxies={"http": http_proxy})
    if transcript:
        break
    
print(transcript)