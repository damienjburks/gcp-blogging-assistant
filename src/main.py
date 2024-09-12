import logging
import functions_framework
from flask import jsonify, request

logging.basicConfig(level=logging.INFO)

@functions_framework.http
def main(request):
    logging.info("Function triggered with method: %s", request.path)
    
    if request.path == '/getVideoId':
        return get_video_id(request)
    elif request.path == '/sendConfirmationEmail':
        return send_confirmation_email(request)
    elif request.path == '/generateBlogPost':
        return generate_blog_post(request)
    elif request.path == '/commitBlogToGitHub':
        return commit_blog_to_github(request)
    elif request.path == '/sendEmail':
        return send_email(request)
    else:
        return jsonify({"error": "Unknown endpoint"}), 404

def get_video_id(request):
    data = request.get_json()
    # Assuming you process and return some information
    video_info = {"videoId": "123456", "isShort": False}
    return jsonify(video_info), 200

def send_confirmation_email(request):
    data = request.get_json()
    # Process the request and return a response
    response = {"Status": "Video is confirmed as technical!"}
    return jsonify(response), 200

def generate_blog_post(request):
    data = request.get_json()
    # Assuming you generate the blog post based on videoType
    video_type = data.get("videoType")
    blog_post = {
        "videoName": data.get("videoName"),
        "blogPostContents": f"Blog post for {video_type} video."
    }
    return jsonify(blog_post), 200

def commit_blog_to_github(request):
    data = request.get_json()
    # Mock response for committing blog post to GitHub
    commit_response = {
        "commitId": "abcdef123456",
        "branchName": "main"
    }
    return jsonify(commit_response), 200

def send_email(request):
    data = request.get_json()
    # Mock email sending result
    email_result = {"status": "Email sent successfully!"}
    return jsonify(email_result), 200
