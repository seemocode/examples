/* CIS 4110 A1. 
 * Student Name: Tasnim Shahin. Student Number: 0892325
 */
package a1_4110;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.*;
import java.net.*;
import java.util.*;
import javax.swing.*;
import javax.swing.text.MutableAttributeSet;
import javax.swing.text.SimpleAttributeSet;
import javax.swing.text.StyleConstants;
import javax.swing.text.StyledDocument;

public class TheServer {

	//Server Port Number
    private static final int PORT = 4110;
    static JButton exitButton = new JButton("Close Server");
    static boolean openClient = true;
    static boolean optionPicked = false;
    
    //Store PrintWriter of clients  
    private static HashSet<PrintWriter> clientWriters = new HashSet<PrintWriter>();

    /**
     * main will set up the server connection in new thread, and open server window
     */
	public static void main(String[] args) {
    	String address = "";
    	
    	try {
    		InetAddress ipAddr = InetAddress.getLocalHost();
            address = ipAddr.getHostAddress();
        	
            //ask user if client or server should be created
        	boolean openClient = createPreServerFrame();
        	if (openClient) {
        		TheClient newClient = new TheClient();
            	newClient.openClients();
        	} //else it will continue to create server
        	
        	ServerSocket listener = new ServerSocket(PORT);
        	System.out.println("The chat server is running on ip address: " + address);
        	
        	Thread thread = new Thread("Server Thread") { //runs server set up in new thread 
        		public void run(){
        			while (true) {
        				try {
        					new Handler(listener.accept()).start(); 
        				}catch(IOException e) {
        				} 
        			}         
        		}
        	};

        	thread.start();
        	   
        	//open separate window saying server has started, shows ip address to users 
        	createServerFrame(address);
        	
        	//listener for exit button
        	exitButton.addActionListener(new ActionListener() { 
	        	public void actionPerformed(ActionEvent e) { 
	        		try {
	    				listener.close();
	    				} catch(IOException ex) {}
	        		System.exit(0);
	        	} 
	        } );
    	}catch(IOException e) {
        	//means server already running
    		//open client instead
        	TheClient newClient = new TheClient();
        	newClient.openClients();
	      } 
    }
	
	public static void createServerFrame(String address) {
    	JFrame serverFrame = new JFrame("Server Frame");
    	JTextPane textPane = new JTextPane();
    	
    	serverFrame.getContentPane().add(exitButton, BorderLayout.BEFORE_FIRST_LINE);
    	
    	textPane.setEditable(false);
    	serverFrame.getContentPane().add(new JScrollPane(textPane), "Center");
    	textPane.setText("The chat server is running on ip address: " + address + "\n" + 
    	"Please run program again to create clients");
    	serverFrame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
    	
    	//add attributes to center and format text 
    	StyledDocument doc = textPane.getStyledDocument();
    	SimpleAttributeSet center = new SimpleAttributeSet();
    	StyleConstants.setAlignment(center, StyleConstants.ALIGN_CENTER);
    	doc.setParagraphAttributes(0, doc.getLength(), center, false);
    	MutableAttributeSet TextPaneAttri = textPane.getInputAttributes();
    	StyleConstants.setFontSize(TextPaneAttri,18); //changes font size
    	doc.setCharacterAttributes(0, doc.getLength() + 1, TextPaneAttri, false);
    	
    	serverFrame.setSize(350,200);
    	serverFrame.getContentPane().setBackground(Color.BLACK);
    	serverFrame.setVisible(true);
    	
    }
	
	public static boolean createPreServerFrame() {
    	JFrame serverFrame = new JFrame("Start Anonymous Broadcast");
    	JTextPane textPane = new JTextPane();
    	JButton serverButton = new JButton("Server");
        JButton clientButton = new JButton("Client");
    	serverFrame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
    	
    	textPane.setEditable(false);
    	serverFrame.add(new JScrollPane(textPane),BorderLayout.NORTH); 
    	serverFrame.add(serverButton,BorderLayout.WEST);
    	serverFrame.add(clientButton,BorderLayout.EAST);
    	serverFrame.getContentPane().setBackground(Color.BLACK);
    	textPane.setText("Welcome to Anonymous Broadcast!\n" + "Create Server or Client?");
    	
    	//add attributes to center and size text 
    	StyledDocument styleDoc = textPane.getStyledDocument();
    	SimpleAttributeSet formatTextPane = new SimpleAttributeSet();
    	MutableAttributeSet TextPaneAttri = textPane.getInputAttributes();
    	StyleConstants.setAlignment(formatTextPane, StyleConstants.ALIGN_CENTER);
    	styleDoc.setParagraphAttributes(0, styleDoc.getLength(), formatTextPane, false);
    	StyleConstants.setFontSize(TextPaneAttri,26); //changes font size
    	styleDoc.setCharacterAttributes(0, styleDoc.getLength() + 1, TextPaneAttri, false);
    	
    	serverFrame.setSize(500,310);
    	serverFrame.setVisible(true);
    	
    	while (optionPicked == false) {
    		//wait till button clicked
    		//listener to open server button 
	    	serverButton.addActionListener(new ActionListener() { 
	        	public void actionPerformed(ActionEvent e) { 
	        			openClient = false;
	        			optionPicked = true;
	        			serverFrame.setVisible(false);
	        	} 
	        } );
	    	
	    	//listener to open client 
	    	clientButton.addActionListener(new ActionListener() { 
	        	public void actionPerformed(ActionEvent e) { 
	        			openClient = true;
	        			optionPicked = true;
	        			serverFrame.setVisible(false);
	        	} 
	        } );    
    	}
    	
    	return openClient;
    	
    }

    /**
     * The handler class will enter listening loop, 
     * and broadcast the messages from clients into the printer writer 
     */
	private static class Handler extends Thread {
        private Socket socket;
        private BufferedReader in;
        private PrintWriter out;
        
        //Set handler thread
        public Handler(Socket socket) {
            this.socket = socket;
            
        }

        /**
         * Registers the client in the output stream, then loops to get input and
         * broadcasts them.
         */
        public void run() {
        	try {

        		// Create character streams for the socket.
                in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
                out = new PrintWriter(socket.getOutputStream(), true);

                //add the printer writer for the client in global set 
                clientWriters.add(out);

                //keep accepting messages from this client and broadcast them on the output stream 
                while (true) {
                	String input = in.readLine();
                    if (input == null) {
                        return;
                    }
                    for (PrintWriter writer : clientWriters) {
                    	writer.println(input + "");
                    }
                    
                }
            } catch (IOException e) {
                System.out.println(e);
            } finally {
                // When client connection closes
            	//remove print writer from the set
                if (out != null) {
                    clientWriters.remove(out);
                }
                //and close its socket.
                try {
                    socket.close();
                } catch (IOException e) {
                } 
            }
        }
    }

}
