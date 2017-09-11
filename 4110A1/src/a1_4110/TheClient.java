/* CIS 4110 A1. 
 * Student Name: Tasnim Shahin. Student Number: 0892325
 */
package a1_4110;

import java.net.*;
import java.text.SimpleDateFormat;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.image.BufferedImage;
import java.io.*;
import java.util.*;

import javax.swing.*;
import javax.swing.text.SimpleAttributeSet;
import javax.swing.text.Style;
import javax.swing.text.StyleConstants;
import javax.swing.text.StyledDocument;

public class TheClient {
	
    JFrame clientFrame = new JFrame("Anonymous Broadcast"); //Screen elements 
    JTextField textField = new JTextField(40);
    JTextPane messageArea = new JTextPane();
    StyledDocument doc = messageArea.getStyledDocument();
    JButton exitButton = new JButton("Exit Chat");
    JCheckBox timeCheckbox = new JCheckBox("Show Time Stamp for Messages");
    JButton sendEmojiButton = new JButton("Send Smiley");
    JButton changeFontColorButton = new JButton("Change Font Color");
    static ImageIcon SMILE_IMG=createImage();
    
    String[] colorList = new String[] {"Black", "Blue","Red", "Green","Grey"};
    JComboBox<String> colorListComboBox = new JComboBox<>(colorList);

    boolean addTime = false; 
    Style styleWrite = messageArea.addStyle("Write Style", null);
    
    BufferedReader in; //store messages passed from server
    PrintWriter out;

    /*Creates customized class to support GIF background
     * Reference: http://stackoverflow.com/questions/1064977/setting-background-images-in-jframe
     **/
    class ImagePanel extends JComponent {
        private Image image;
        public ImagePanel(Image image) {
            this.image = image;
        }
        @Override
        protected void paintComponent(Graphics smileGraphic) {
            super.paintComponent(smileGraphic);
            smileGraphic.drawImage(image, 0, 0, this);
        }
    }
    
    /**
     * Creates the Client frame and creates the required listeners
     */
    public TheClient() {
    	
    	//add GIF background image
    	Image myImage;
    	URL url = TheServer.class.getResource("/resources/swirlbackground.gif");
    	myImage = new ImageIcon(url).getImage();
		clientFrame.setContentPane(new ImagePanel(myImage));
		
    	//Format Client Frame
		clientFrame.getContentPane().setBackground(Color.black); 
        clientFrame.setLayout(new BorderLayout());
        clientFrame.setSize(650,600);
        clientFrame.setResizable(false);
        
        //format text and message fields
        textField.setForeground(Color.DARK_GRAY);
    	textField.setText("Type Here"); 
    	textField.setPreferredSize(new Dimension(400, 40));
        messageArea.setEditable(false);
        timeCheckbox.setForeground(Color.WHITE);
        StyleConstants.setForeground(styleWrite, Color.black);

        //add elements to frame 
        clientFrame.getContentPane().add(textField,BorderLayout.SOUTH);
        clientFrame.getContentPane().add(exitButton, BorderLayout.BEFORE_FIRST_LINE);
        
        //create tab for messages and options
        JTabbedPane tabbedPane = new JTabbedPane();
        JPanel optionTab = new JPanel();
        JPanel messageTab = new JPanel();
        
        //add elements to option tab
        optionTab.add(timeCheckbox);
        optionTab.add(changeFontColorButton);
        optionTab.add(colorListComboBox);
        optionTab.add(sendEmojiButton);
        
        //add elements to message tab
        messageTab.setLayout( null );
        JScrollPane messagesScroll = new JScrollPane(messageArea);
        messagesScroll.setBounds( 50, 10, 530, 430 );
        messagesScroll.setPreferredSize(new Dimension(200, 200));
        messageTab.add( messagesScroll);
        
        //format tabs
        optionTab.setBackground(Color.BLACK);
        messageTab.setBackground(Color.BLACK);

        //add tabs to client frame
        tabbedPane.addTab("Message", messageTab);
        tabbedPane.addTab("Options", optionTab);
        clientFrame.getContentPane().add(tabbedPane, BorderLayout.CENTER);

        // Add required listeners
        textField.addActionListener(new ActionListener() {
            /**
             * Action is based on enter key in text field. 
             * Message will be sent to server to pass along 
             * Text field will then be cleared 
             */
            public void actionPerformed(ActionEvent e) {
                out.println(textField.getText()); 
                textField.setText("");
            }
        });
        
        timeCheckbox.addActionListener(new ActionListener() { 
        	public void actionPerformed(ActionEvent e) { 
        		if (addTime) {
        			addTime = false;
        		} else {
        			addTime = true;
        		}
        	} 
        } ); 
        
        changeFontColorButton.addActionListener(new ActionListener() { 
        	public void actionPerformed(ActionEvent e) { 
        		String selectedColor = (String) colorListComboBox.getSelectedItem();
        		if (selectedColor.equals("Blue")) {
        			StyleConstants.setForeground(styleWrite, Color.blue);
        		} else if (selectedColor.equals("Red")) {
        			StyleConstants.setForeground(styleWrite, Color.RED); 
        		} else if (selectedColor.equals("Black")) {
        			StyleConstants.setForeground(styleWrite, Color.black); 
        		} else if (selectedColor.equals("Green")) {
        			StyleConstants.setForeground(styleWrite, Color.GREEN); 
        		} else if (selectedColor.equals("Grey")) {
        			StyleConstants.setForeground(styleWrite, Color.GRAY); 
        		}
        	} 
        } ); 
    }

    /**
     * Ask user for server IP address, then return it as a string.
     */
	private String getServerIPAddress() {
		return JOptionPane.showInputDialog(clientFrame,
				"Please Enter IP Address of the Server:",
				"Welcome to Anonymous Broadcast",
				JOptionPane.QUESTION_MESSAGE);
		}

    /**
     * First connects to the server 
	 * then listens for messages from the server to print to screen
	 * button functionality is also processed 
     */
    private void run() throws IOException {

        // Make connection and initialize streams
        String serverAddress = getServerIPAddress();
        Socket socket = new Socket(serverAddress, 4110);
        in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
        out = new PrintWriter(socket.getOutputStream(), true);
        
        Style styleTime = messageArea.addStyle("Time Style", null);
        StyleConstants.setForeground(styleTime, Color.blue);
        
        exitButton.addActionListener(new ActionListener() { 
        	public void actionPerformed(ActionEvent e) { 
        		try {
					socket.close();
				} catch (IOException e1) {
				}
        		System.exit(0);
        	} 
        } );
        
        sendEmojiButton.addActionListener(new ActionListener() { 
        	public void actionPerformed(ActionEvent e) { 
        		out.println(":)"); 
        	} 
        } );
        
        // Process messages from server
        while (true) {
        	
        	//get current time to print to screen
            Calendar cal = Calendar.getInstance();
            SimpleDateFormat sdf = new SimpleDateFormat("HH:mm:ss a");
            String timeStr = sdf.format(cal.getTime());
        	
            String line = in.readLine();
            int length = line.length();
            
            if (length >= 40) {
            	if(addTime) {
            		try { doc.insertString(doc.getLength(), "\t\t" + timeStr + "\n",styleTime); }
            		catch (Exception e){}	
            	}
            	messageArea = splitLongMessages(line,messageArea,timeStr,styleWrite);
            } else { 
            	if(addTime) {
            		try { doc.insertString(doc.getLength(), "\t\t" + timeStr + "\n",styleTime); }
            		catch (Exception e){}	
            	}
            	
            	if (line.equals(":)") || line.equals(":) ")) { //if user types in a single smile :) in message 
            		final SimpleAttributeSet attrs=new SimpleAttributeSet();
                	StyleConstants.setIcon(attrs, SMILE_IMG);
                	try { 
                		doc.insertString(doc.getLength(),"Anonymous: ", styleWrite); 
                		doc.insertString(doc.getLength(),":) \n", attrs); 
                	} catch (Exception ex){}
            	} else {
            		try { 
            			doc.insertString(doc.getLength(),"Anonymous: " + line + "\n",styleWrite); 
            		}
            		catch (Exception e){}
            	}
            	
            }
        }
        
    }

    /**
     * opens the client window
     */
	public void openClients() {
		TheClient client = new TheClient();
        client.clientFrame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        client.clientFrame.setVisible(true);
        try {
        	client.run(); 
        } catch(IOException e) {
        	System.out.println("Connection down");
        	System.exit(0);
        }
    }
	
	/*Will split long strings into smaller messages, to fit better within screen*/
	public JTextPane splitLongMessages(String message,JTextPane messageArea,String timeStr,Style  styleWrite) {
		
		//print first 40 characters 
		try { doc.insertString(doc.getLength(),"Anonymous: " + message.substring(0,40) + "\n",styleWrite); }
        catch (Exception e){}
		
		int length = message.length();
    	String restOfTheMessage = message.substring(40, length);
    	
    	length = restOfTheMessage.length();
		
    	while (restOfTheMessage.length() > 0) {
    		if (restOfTheMessage.length() >= 40) {
    			//print another 40 characters 
    			try { doc.insertString(doc.getLength(),"\t" + restOfTheMessage.substring(0,40) + "\n",styleWrite); }
                catch (Exception e){}
    			restOfTheMessage = restOfTheMessage.substring(40, restOfTheMessage.length());
            } else {
            	//print the last characters
            	try { doc.insertString(doc.getLength(),"\t" + restOfTheMessage + "\n",styleWrite); }
                catch (Exception e){}
            	break;
            }
    	}
    	
		return messageArea;
    }
	
	/*Creates the smile image 
	 * Reference http://java-sl.com/tip_autoreplace_smiles.html for method*/
	 static ImageIcon createImage() {
	        BufferedImage resolution=new BufferedImage(17, 17, BufferedImage.TYPE_INT_ARGB);
	        Graphics smileGraphic = resolution.getGraphics();
	        ((Graphics2D)smileGraphic).setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
	        smileGraphic.setColor(Color.CYAN);
	        smileGraphic.fillOval(0,0,16,16);
	 
	        smileGraphic.setColor(Color.black);
	        smileGraphic.drawOval(0,0,16,16);
	 
	        smileGraphic.drawLine(4,5, 6,5);
	        smileGraphic.drawLine(4,6, 6,6);
	 
	        smileGraphic.drawLine(11,5, 9,5);
	        smileGraphic.drawLine(11,6, 9,6);
	 
	        smileGraphic.drawLine(4,10, 8,12);
	        smileGraphic.drawLine(8,12, 12,10);
	        smileGraphic.dispose();
	 
	        return new ImageIcon(resolution);
	    }
	
}
