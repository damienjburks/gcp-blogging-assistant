import logging
import hashlib
import functions_framework

from flask import jsonify, request

from client.youtube_client import YouTubeClient
from client.openai_client import OpenAIClient
from client.git_client import GitClient

logging.basicConfig(level=logging.INFO)


@functions_framework.http
def main(request):
    logging.info("Function triggered with method: %s", request.path)

    if request.path == "/getVideoId":
        return jsonify(action_get_video_id(request)), 200
    elif request.path == "/generateBlogPost":
        return jsonify(action_generate_blog_post(request)), 200
    elif request.path == "/commitBlogToGitHub":
        return jsonify(action_commit_blog_to_github(request)), 200
    else:
        return jsonify({"error": "Unknown endpoint"}), 404


def action_generate_blog_post(request):
    """
    This function takes in a video ID and returns the blog post contents.
    """
    video_url = request.get_json()["videoUrl"]
    video_name = request.get_json()["videoName"]

    transcript = YouTubeClient().get_video_transcript(video_url)
    markdown_blog = OpenAIClient().ask(transcript, video_name, "non-technical")
    return {"blogPostContents": markdown_blog}


def action_commit_blog_to_github(request):
    """
    This function takes in a video title and blog post contents
    and returns the commit ID and branch name.
    """
    video_name = request.get_json().get("videoName")
    blog_post_contents = request.get_json().get("blogPostContents")

    git_client = GitClient()

    branch_name = hashlib.sha256(video_name.encode("utf-8")).hexdigest()
    repo = git_client.clone(branch_name)

    commit_info = git_client.commit(video_name, blog_post_contents, repo)
    git_client.push(repo)

    return {"commitId": commit_info.hexsha, "branchName": branch_name}
