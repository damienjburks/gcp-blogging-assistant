"""
Secrets Manager Module
"""

import os
import logging

from google.cloud import secretmanager

logging.getLogger().setLevel(logging.INFO)

PROJECT_ID = os.environ.get("PROJECT_ID")


class SecretsManagerClient:
    """
    Class for accessing Google Cloud Secret Manager.
    This class is designed to retrieve secret values from Google Cloud Secret Manager.
    It uses the Google Cloud SDK to interact with the Secret Manager service.
    """

    def __init__(self):
        self.client = secretmanager.SecretManagerServiceClient()

    def get_secret(self, secret_id, version_id="latest"):
        """
        Access the payload of the given secret version from Google Cloud Secret Manager.

        Args:
            secret_id: The name of the secret in Secret Manager.
            version_id: The version of the secret. Defaults to 'latest'.

        Returns:
            The secret payload as a string.
        """
        # Build the resource name of the secret version
        name = f"projects/{PROJECT_ID}/secrets/{secret_id}/versions/{version_id}"

        # Access the secret version
        response = self.client.access_secret_version(name=name)

        # Extract and return the secret payload
        secret_payload = response.payload.data.decode("UTF-8")

        logging.info("Secret retrieved successfully: %s", secret_id)

        return secret_payload
