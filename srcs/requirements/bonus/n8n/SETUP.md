# n8n workflow setup

## What it does

The corrector visits a form URL, enters their name and email, submits.  
They receive an email sent automatically by the n8n workflow running inside Docker.

---

## Step 1 — Get a Gmail App Password

> Required because Gmail blocks direct login from third-party apps.

1. Go to your Google Account → **Security**
2. Enable **2-Step Verification** if not already done
3. Go to **App passwords** (search "app passwords" in the Google account search bar)
4. Create a new app password → name it "n8n"
5. Copy the 16-character password shown

---

## Step 2 — Configure SMTP credentials in n8n

1. Open `https://n8n.dinguyen.42.fr`
2. Go to **Settings → Credentials → New credential**
3. Choose **SMTP**
4. Fill in:
   - Host: `smtp.gmail.com`
   - Port: `465`
   - SSL: enabled
   - User: your Gmail address
   - Password: the app password from step 1
5. Save as **Gmail SMTP**

---

## Step 3 — Import the workflow

1. In n8n, go to **Workflows → Import from file**
2. Select `srcs/requirements/bonus/n8n/workflow.json`
3. Open the **Send Email** node and update `fromEmail` with your Gmail address
4. **Activate** the workflow (toggle in the top right)

---

## Step 4 — Demo

The form is accessible at:

```
https://n8n.dinguyen.42.fr/form/inception-demo
```

The corrector enters their name and email → they receive an email within seconds.
