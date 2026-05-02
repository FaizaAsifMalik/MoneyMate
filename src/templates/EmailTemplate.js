/**
 * Abstract Email Template
 * Template Method Pattern for email generation
 */
class EmailTemplate {
  constructor() {
    if (new.target === EmailTemplate) {
      throw new TypeError('Cannot construct EmailTemplate instances directly');
    }
  }

  /**
   * Template method - defines the skeleton
   */
  generate(data) {
    const subject = this.getSubject(data);
    const header = this.getHeader(data);
    const body = this.getBody(data);
    const footer = this.getFooter(data);

    return {
      subject,
      html: this._wrapInHtml(header, body, footer),
    };
  }

  /**
   * Abstract methods - must be implemented by subclasses
   */
  getSubject(data) {
    throw new Error('getSubject() must be implemented');
  }

  getHeader(data) {
    throw new Error('getHeader() must be implemented');
  }

  getBody(data) {
    throw new Error('getBody() must be implemented');
  }

  /**
   * Hook method - can be overridden
   */
  getFooter(data) {
    return `
      <p style="color: #666; font-size: 12px; margin-top: 30px;">
        Best regards,<br>
        The MoneyMate Team
      </p>
      <p style="color: #999; font-size: 11px;">
        This is an automated email. Please do not reply.
      </p>
    `;
  }

  /**
   * Private method - wraps content in HTML
   */
  _wrapInHtml(header, body, footer) {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
          .body { padding: 20px; background-color: #f9f9f9; }
          .footer { padding: 20px; text-align: center; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">${header}</div>
          <div class="body">${body}</div>
          <div class="footer">${footer}</div>
        </div>
      </body>
      </html>
    `;
  }
}

module.exports = EmailTemplate;