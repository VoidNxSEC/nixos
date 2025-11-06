//! Local model management for Unified LLM Platform
//! 
//! This crate will provide VRAM-aware model loading, backend management, etc.

pub const VERSION: &str = env!("CARGO_PKG_VERSION");

// TODO: Migrate from ML Offload API