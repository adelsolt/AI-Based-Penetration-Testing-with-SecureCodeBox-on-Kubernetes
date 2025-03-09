# finetune.py
import os
import torch
from datasets import load_dataset
from transformers import AutoTokenizer, AutoModelForCausalLM, TrainingArguments, Trainer
from peft import LoraConfig, get_peft_model

# 1. Load your dataset
# Suppose you have your data in "mydata.jsonl" with fields instruction, input, and output
# We'll create a "prompt" from that for instruction tuning.

dataset = load_dataset('json', data_files='mydata.jsonl')
train_data = dataset['train']  # if there's no split, it'll just be 'train'

def format_example(example):
    # This function merges instruction + input into a single prompt
    # Then attaches the 'output' as a label.
    if example["input"].strip():
        prompt = f"Instruction: {example['instruction']}\nInput: {example['input']}\nAnswer:"
    else:
        prompt = f"Instruction: {example['instruction']}\nAnswer:"
    return {
        "prompt": prompt,
        "target": example["output"]
    }

train_data = train_data.map(format_example)

# 2. Load the base model and tokenizer
base_model_path = "./deepseek-r1"  # or whatever path your local model is in
tokenizer = AutoTokenizer.from_pretrained(base_model_path, use_fast=False)
model = AutoModelForCausalLM.from_pretrained(
    base_model_path,
    load_in_8bit=True,  # or load_in_4bit=True if supported
    device_map="auto"   # automatically chooses GPU if available
)

# 3. Configure LoRA (PEFT)
lora_config = LoraConfig(
    r=8,            # rank
    lora_alpha=32,
    target_modules=["q_proj","v_proj"],  # depends on model architecture
    lora_dropout=0.05,
    bias="none",
    task_type="CAUSAL_LM"
)

model = get_peft_model(model, lora_config)

# 4. Tokenize function for the trainer
def tokenize(entry):
    # We handle both prompt (input) and target
    # Usually you do something like:
    outputs = tokenizer(
        entry["prompt"],
        truncation=True,
        max_length=512
    )
    # Then your label is the concatenation of prompt + answer, or you handle them separately.
    # For a quick approach, let's just tack them together:
    with tokenizer.as_target_tokenizer():
        labels = tokenizer(
            entry["target"],
            truncation=True,
            max_length=256
        )["input_ids"]

    outputs["labels"] = labels
    return outputs

train_data = train_data.map(tokenize, batched=False)

# 5. Training arguments
training_args = TrainingArguments(
    output_dir="./finetuned-deepseek-r1",
    overwrite_output_dir=True,
    num_train_epochs=3,
    per_device_train_batch_size=1,
    gradient_accumulation_steps=8,
    fp16=True,  # Mixed precision if your GPU supports it
    save_steps=100,
    logging_steps=50
)

# 6. Initialize Trainer
trainer = Trainer(
    model=model,
    args=training_args,
    train_dataset=train_data,
)

# 7. Fine-tune
trainer.train()

# 8. Save the final model (LoRA adapters)
trainer.save_model("./finetuned-deepseek-r1")
