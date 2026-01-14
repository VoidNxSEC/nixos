"""Replicate API client for logo generation."""
import os
import json
import logging
from typing import Dict, Any, Optional
import replicate
from config import Config

logger = logging.getLogger(__name__)

class ReplicateClient:
    """Client for interacting with the Replicate API."""
    
    def __init__(self, api_token: Optional[str] = None):
        """Initialize the Replicate client.
        
        Args:
            api_token: Optional API token. If not provided, uses Config.
        """
        self.api_token = api_token or Config.REPLICATE_API_TOKEN
        Config.validate()
        
        # Set the API token for replicate
        os.environ["REPLICATE_API_TOKEN"] = self.api_token
        
    def generate_logo(
        self,
        prompt: str,
        negative_prompt: Optional[str] = None,
        style: Optional[str] = None,
        **kwargs
    ) -> Dict[str, Any]:
        """Generate a logo using the LogoAI model.
        
        Args:
            prompt: Text description of the logo to generate
            negative_prompt: What to avoid in the generation
            style: Style modifier for the logo
            **kwargs: Additional parameters to override defaults
            
        Returns:
            Dictionary containing the result and metadata
        """
        # Build the full prompt
        full_prompt = prompt
        if style:
            full_prompt = f"{style} style, {prompt}"
            
        # Prepare input parameters
        input_params = {
            "prompt": full_prompt,
            "negative_prompt": negative_prompt or "low quality, blurry, pixelated",
            **Config.DEFAULT_PARAMS,
            **kwargs
        }
        
        # Remove None values
        input_params = {k: v for k, v in input_params.items() if v is not None}
        
        logger.info(f"Generating logo with prompt: {full_prompt}")
        logger.debug(f"Parameters: {json.dumps(input_params, indent=2)}")
        
        try:
            # Run the model
            output = replicate.run(
                Config.MODEL_VERSION,
                input=input_params
            )
            
            # Handle the output (could be URL or file path)
            if isinstance(output, list) and len(output) > 0:
                output_url = output[0]
            else:
                output_url = str(output)
                
            result = {
                "success": True,
                "output_url": output_url,
                "prompt": full_prompt,
                "parameters": input_params,
                "model": Config.MODEL_VERSION
            }
            
            logger.info(f"Logo generated successfully: {output_url}")
            return result
            
        except Exception as e:
            logger.error(f"Error generating logo: {str(e)}")
            return {
                "success": False,
                "error": str(e),
                "prompt": full_prompt,
                "parameters": input_params
            }
