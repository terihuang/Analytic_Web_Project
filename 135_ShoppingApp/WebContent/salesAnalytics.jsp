<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1"%>
 <%@ page import = "java.sql.*" import = "java.until.*" import="java.util.List"
	import="java.util.ArrayList" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
<title>Sales Analytics</title>
<style>


</style>

</head>
<body>
	<% 
		final long pageStrTime = System.currentTimeMillis();
	
	
		if(session.getAttribute("roleName") != null) { 
		String role = session.getAttribute("roleName").toString();
		
		if("owner".equalsIgnoreCase(role) == true){
				Connection conn = null;
				PreparedStatement pst = null;
				Statement stmt = null;
				ResultSet myRs = null;
				ResultSet pRs = null;
				ResultSet cRs = null;
				ResultSet catRs = null;
				
			
				
				// get offset of row and column
				String rowOffset = request.getParameter("rowOffs");
				String colOffset = request.getParameter("colOffs");
				String buttPress = request.getParameter("nextButton");
				//String str1 = request.getParameter("orderBy");
				//String str2 = request.getParameter("analysisType");
				String catego = request.getParameter("categ");
				String cart = "";
				String whr = "";
				
				//System.out.println("RowOff: " + rowOffset + " | colOff: " + colOffset + " |orderBy: " + str1 + " |analysisType: " + str2);
				
				int prevRowOffset = 0;
				int prevColOffset = 0;
				int currRowOffset = 0;
				int currColOffset = 0;
				
				if(catego == null || catego.equals("all")){
					cart = "products_in_cart AS cart";
					//System.out.print("sss");
					whr = " ";
				}
				else{
					//System.out.print(catego + Integer.parseInt(catego));
					cart = "(SELECT cart_id , product_id, price, quantity FROM (select prod.id as id, product_name, cat.id AS cat_id from " + 
							" (select id from category) as cat "+
							" left join (select id, product_name, category_id from product) as prod on prod.category_id =cat.id "+
							" where cat.id = " + Integer.parseInt(catego) + " ) as sel left join products_in_cart as pc on pc.product_id = sel.id) AS cart ";
					whr = " where category_id = " + Integer.parseInt(catego) +" ";
				}
				if( buttPress == null) {
					currRowOffset = 0;
					currColOffset = 0;
				}
				
				// increament row offset by 20 if next 20 customer/state pressed
				else if ( buttPress.equals("nextRow") ){
					
					if (rowOffset == null) prevRowOffset = 0;
					else prevRowOffset = Integer.parseInt(rowOffset);
					
					if(colOffset == null) prevColOffset = 0;
					else {
						prevColOffset = Integer.parseInt(colOffset);
					
						//System.out.print("Prev Row Offset: " + prevRowOffset + ".  |");
					

					}
					
					currRowOffset = prevRowOffset + 20;
					
					//System.out.println("Curr Row Offset: " + currRowOffset);
					//System.out.println("");
				
					currColOffset = prevColOffset;
				}
				
				// increament column offset by 10 if next 10 products pressed
				else if( buttPress.equals("nextCol")){
					
					if (rowOffset == null) prevRowOffset = 0;
					else prevRowOffset = Integer.parseInt(rowOffset);
					
					if (colOffset == null) prevColOffset = 0;
					else {
						prevColOffset = Integer.parseInt(colOffset);
					}
					
					currRowOffset = prevRowOffset;
					currColOffset = prevColOffset + 10;	
				}				
				
				
				
				try{
				

					Class.forName("org.postgresql.Driver");

					conn = DriverManager.getConnection("jdbc:postgresql://localhost/shoppingAppDB","postgres", "cse135");
					conn.setAutoCommit(false);
					stmt = conn.createStatement();
					catRs = stmt.executeQuery("select * from category");
					conn.commit();
		        	conn.setAutoCommit(true);
					%>

				<h3> Hello <%= session.getAttribute("personName") %> </h3>
				<h3> Sales Analytics Page </h3>

					
				<table cellspacing="5">
				<tr>
					<td valign="top"> <jsp:include page="./menu.jsp"></jsp:include></td>

						
					<td>
					
					<% if( buttPress == null ) { %>
						<form method = post action="salesAnalytics.jsp">
						
							<input type = "submit" value = "Run Query"/>
							<p>Category</p>
							<select name = "categ">
								<option value = "all">All</option>
								<% while (catRs.next()){%>
									<option value = "<%= catRs.getString("id")%>"><%= catRs.getString("category_name")%></option>
								<%}
								catRs.close();%>
							</select>
						
							<p>Choose Analysis Type</p>
							<select name = "analysisType">
								<option value = "customer">Customers</option>
								<option value = "state">States</option>
							</select>
							
							<p>Order Products By</p>
							<select name = "orderBy">
								<option value = "alpha">Alphabet</option>
								<option value = "topk">Top-K</option>
							</select>
							
						</form>
						
						<% } %>
						
					</td>
					
					
					<%
				    String analy_type = request.getParameter("analysisType");
					String prod_order = request.getParameter("orderBy");
					String prodQuery = "";
					String rowQuery = "";
					String formQuery = "";
					
					
					//conn.setAutoCommit(false);
					//stmt = conn.createStatement();
					
					// order by alphabetical, default also order by alphabet 
					if (prod_order == null || prod_order.equals("alpha")) {

						prodQuery = "SELECT id, product_name FROM product " +whr+" ORDER BY product_name LIMIT 10 OFFSET " + currColOffset;
						// customer by alphabet
						if ( analy_type == null || analy_type.equals("customer")){
							
							// customer by alphabtic with total sales
							rowQuery = "SELECT c.id, person_name AS row_name, COALESCE( SUM(t.amount), 0 ) as total_sale "+
										"FROM "+
										"(SELECT id, person_name FROM person ORDER BY person_name ASC LIMIT 20 OFFSET " + currRowOffset + " ) as c "+
								 	   	"LEFT JOIN (SELECT id, person_id FROM shopping_cart where is_purchased = TRUE) AS sc ON sc.person_id = c.id "+ 
								       	"LEFT JOIN "+
								        "(SELECT cart.cart_id AS cart_id,  SUM(cart.price*cart.quantity) AS amount FROM " + cart + " group by cart.cart_id) AS t "+
								       	"ON t.cart_id = sc.id "+
								   		"group by c.id, person_name "+
										"order by person_name";
							
							formQuery = "SELECT c.person_name AS row_name, p.id, p.product_name, SUM(t.amount) as prod_sale " +
									"FROM(SELECT id, person_name FROM person ORDER BY person_name ASC LIMIT 20 OFFSET " + currRowOffset + " ) as c "+
									"LEFT JOIN (SELECT id,  person_id FROM shopping_cart WHERE is_purchased = TRUE) AS sc ON sc.person_id = c.id "+ 
									"LEFT JOIN "+
									"(SELECT cart.cart_id AS cart_id, cart.product_id AS product_id, (cart.price*cart.quantity) AS amount FROM "+cart+" ) AS t "+
									"ON t.cart_id = sc.id "+
									"LEFT JOIN (SELECT id, product_name FROM product "+whr+ " ORDER BY product_name LIMIT 10" + currColOffset + " ) AS p "+
									"ON p.id = t.product_id "+
									"GROUP BY c.person_name, p.id, p.product_name "+
									"ORDER BY person_name , p.product_name";
;
						}
						
						// state by alphabet
						else{
							rowQuery = "select s.id as id, state_code AS row_name, COALESCE(SUM(t.amount), 0) AS total_sale from "+
									"(select id, state_code from state order by state_code limit 20 OFFSET " + currRowOffset + " ) as s "+
									"left join (SELECT id, person_name, state_id from person) AS p on p.state_id = s.id "+
									"left join (SELECT id,  person_id FROM shopping_cart WHERE is_purchased = TRUE) as sc on p.id = sc.person_id "+
									"left join (SELECT cart.cart_id AS cart_id, SUM(cart.price*cart.quantity) AS amount FROM "+cart+" group by cart.cart_id) AS t on t.cart_id = sc.id "+
									"group by state_code, s.id "+
								    "order by state_code";

							formQuery = "select state_code as row_name, SUM(t.amount) as prod_sale, product_name "+
									"from "+
									"(select state_code, id from state order by state_code limit 20 OFFSET " + currRowOffset + " ) as p "+
									"left join (select state_id, person_name, id from person) as pers on state_id = p.id " +
									"left join (SELECT id,  person_id FROM shopping_cart WHERE is_purchased = TRUE) as sc on pers.id = sc.person_id " +
									"left join (SELECT cart.cart_id AS cart_id, cart.product_id AS product_id, (cart.price*cart.quantity) AS amount FROM " +cart+ ") AS t on t.cart_id = sc.id " +
									"LEFT JOIN (SELECT id, product_name FROM product " +whr+ "ORDER BY product_name LIMIT 10 OFFSET " + currColOffset + " ) AS pd on pd.id = t.product_id " +
									"group by state_code, product_name " +
									"order by state_code";
						}
					  }
					
					
					// order by top sales
					else {
						prodQuery = "SELECT pr.product_name as product_name, COALESCE(sum(cart.price * cart.quantity), 0) AS spend " +
							    	"FROM product pr LEFT JOIN "+cart +" ON cart.product_id = pr.id " +
							    	"GROUP BY product_name " +
							    	"ORDER BY spend DESC LIMIT 10 OFFSET " + currColOffset;
						
						// customer by top sales
						if ( analy_type == null || analy_type.equals("customer")){
							rowQuery = "SELECT p.id, p.person_name AS row_name, COALESCE (SUM(pc.amount),0) AS total_sale FROM " +
									"(SELECT id, person_name from person) AS p " +
									"LEFT JOIN  (SELECT id,  person_id FROM shopping_cart WHERE is_purchased = TRUE) AS sc ON sc.person_id = p.id "+
									"LEFT JOIN (SELECT SUM(cart.price*cart.quantity) AS amount, cart.cart_id AS cart_id FROM "+cart+" GROUP BY cart.cart_id) AS pc ON pc.cart_id = sc.id " +
									"GROUP BY p.id, p.person_name " +
									"ORDER BY total_sale DESC LIMIT 20 OFFSET " + currRowOffset;
							
							formQuery = "SELECT c.person_name AS row_name, c.total as total_sale, COALESCE(SUM(t.amount),0) AS prod_sale, pd.product_name " +
									"FROM "+
									"(SELECT p.id AS id, p.person_name AS person_name, COALESCE (SUM(pc.amount),0) AS total FROM "+
									"(SELECT id, person_name from person) AS p "+
									"LEFT JOIN  (SELECT id,  person_id FROM shopping_cart WHERE is_purchased = TRUE) AS sc  ON  sc.person_id = p.id "+
									"LEFT JOIN (SELECT SUM(cart.price*cart.quantity) AS amount, cart.cart_id AS cart_id FROM "+cart+" GROUP BY cart.cart_id) AS pc ON pc.cart_id = sc.id "+
									"GROUP BY p.id, p.person_name "+
									"ORDER BY total DESC LIMIT 20 OFFSET " + currRowOffset + " ) as c "+
									"LEFT JOIN (SELECT id, is_purchased, person_id FROM shopping_cart) AS sc ON sc.person_id = c.id "+
									"LEFT JOIN (SELECT cart.cart_id AS cart_id , cart.product_id AS product_id, (cart.price*cart.quantity) AS amount FROM "+cart+" ) AS t "+
									"ON t.cart_id = sc.id "+
									"LEFT JOIN "+
									"(select pr.product_name AS product_name, pr.id AS id, COALESCE(sum(cart.price * cart.quantity), 0) as spend "+
									"from product pr left join "+cart+" on (cart.product_id = pr.id) "+
									"group by product_name, pr.id "+
									"order by spend DESC LIMIT 10 OFFSET " + currColOffset + " ) AS pd ON pd.id = t.product_id "+
									"GROUP BY c.person_name, c.total, pd.product_name "+
									"ORDER by c.total DESC ";
									
						}
						
						// state by top sales
						else{
							rowQuery = "select s.id as id, state_code AS row_name, COALESCE(SUM(t.amount), 0) AS total_sale from "+
									"(select id, state_code from state) as s "+
									"left join (SELECT id, person_name, state_id from person) AS p on p.state_id = s.id "+
									"left join (SELECT id,  person_id FROM shopping_cart WHERE is_purchased = TRUE) as sc on p.id = sc.person_id "+
									"left join (SELECT cart.cart_id AS cart_id,  (cart.price*cart.quantity) AS amount FROM "+cart+" ) AS t on t.cart_id = sc.id "+
									"group by state_code, s.id "+
									"order by total_sale DESC LIMIT 20 OFFSET " + currRowOffset;
									
							formQuery = "select state_code AS row_name, total, product_name, COALESCE(SUM(tt.amount),0) AS prod_sale "+
										"from (select s.id as id, state_code, COALESCE(SUM(t.amount), 0) AS total from "+
										"(select id, state_code from state) as s "+
										"left join (SELECT id, person_name, state_id from person) AS p on p.state_id = s.id "+
										"left join (SELECT id,  person_id FROM shopping_cart WHERE is_purchased = TRUE) as sc on p.id = sc.person_id "+
										"left join (SELECT cart.cart_id AS cart_id,  (cart.price*cart.quantity) AS amount FROM "+cart+" ) AS t on t.cart_id = sc.id "+
										"group by state_code, s.id "+
										"order by total DESC limit 20 OFFSET " + currRowOffset + " ) as st "+
										"left join (SELECT id, person_name, state_id from person) AS pp on pp.state_id = st.id "+
										"left join (SELECT id,  person_id FROM shopping_cart WHERE is_purchased = TRUE) as scc on pp.id = scc.person_id "+
										"left join (SELECT cart.cart_id AS cart_id, cart.product_id AS product_id, (cart.price*cart.quantity) AS amount FROM " +cart+ " ) AS tt on tt.cart_id = scc.id "+
										"left join (select pr.product_name AS product_name, pr.id AS id, COALESCE(sum(cart.price * cart.quantity), 0) as spend "+
								        "from product pr left join "+cart+" on (cart.product_id = pr.id) group by product_name, pr.id order by spend DESC LIMIT 10 OFFSET " + currColOffset + " ) AS pddd "+
									     "ON pddd.id = tt.product_id "+
										 "group by row_name, product_name, total "+
										 "order by st.total desc";

						}
					}
					
					// store products in user selected order into a list
					conn.setAutoCommit(false);
					stmt = conn.createStatement();	
					final long prodQstrTime = System.currentTimeMillis();
					pRs = stmt.executeQuery(prodQuery);
					conn.commit();
		        	conn.setAutoCommit(true);
					final long prodQendTime = System.currentTimeMillis();
					System.out.println("Product Header Query Running Time: " + ( prodQendTime- prodQstrTime) + "ms");
					List<String> prodList = new ArrayList<String>();
					int prodCnt = 0;
					
					while (pRs.next()){
						prodList.add(prodCnt, pRs.getString("product_name"));
						prodCnt++;
					}
					
					pRs.close();
					
					// store customers or state in user order into a list
					conn.setAutoCommit(false);
					stmt = conn.createStatement();
					final long rowQstrTime = System.currentTimeMillis();
					cRs = stmt.executeQuery(rowQuery);
					final long rowQendTime = System.currentTimeMillis();
					System.out.println("Row Header Query Running Time: " + ( rowQendTime- rowQstrTime) + "ms");
					List<String> rowList = new ArrayList<String>();
					int rowCnt = 0;
					
					while (cRs.next()) {
						String rowNa = cRs.getString("row_name");
						String rowSale =  cRs.getString("total_sale");
						String rowHeader = rowNa + " ($ " + rowSale + " )";
						rowList.add(rowCnt, rowHeader);
						rowCnt++;
					}
					
					cRs.close();
					
					
					conn.setAutoCommit(false);
					stmt = conn.createStatement();
					final long tableQstrTime = System.currentTimeMillis();
					myRs = stmt.executeQuery(formQuery);
					final long tableQendTime = System.currentTimeMillis();
					System.out.println("Output Data Table Query Running Time: " + ( tableQendTime- tableQstrTime) + "ms");
					
					String currName,prevName = "";
					
					int[][] outTable = new int[20][10];
					
					int cu_index = 0;
					int pr_index = 0;
					boolean start = false;
					
					while( myRs.next() ){
						currName = myRs.getString("row_name");
						//System.out.println(currName);
						//System.out.print(currName);
						if (!start){
							prevName = currName;
							start = true;
						}
						
						if (currName.equals(prevName)){
						
							pr_index = prodList.indexOf(myRs.getString("product_name"));

							if (pr_index != -1) {
								outTable[cu_index][pr_index] = myRs.getInt("prod_sale");
							}
							
							prevName = currName;
							
						}
						
						else{
							cu_index++;
							pr_index = prodList.indexOf(myRs.getString("product_name"));
							
							// if found matching product, store the sales spent on that product
							if (pr_index != -1) {
								outTable[cu_index][pr_index] = myRs.getInt("prod_sale");
							}
							
							prevName = currName;	
						}
						
						if (cu_index >= 19) break;
					}
					
					myRs.close();
					int loopCnt = cu_index + 1;
					
					
					%>
					
					

					<td> 
					<div class = table>
						<table border=1> 
						
							<th> Customer </th>
						
							<% for(int i = 0; i < prodList.size(); i++) { %>
							<th> <%= prodList.get(i) %> </th>
							<%} %>
						
							<% for( int i = 0; i < rowList.size(); i++) { %>
							<tr>
								
								<td> <%= rowList.get(i) %> </td>
								
								<% for( int j = 0; j < prodList.size(); j++) { %>
									<td width = "5%"><%= outTable[i][j] %></td>
								<% } %>
								
							</tr>
							<%} %>
						</table>
						
						<% 
							String rowButton;
							if (analy_type != null ) rowButton = "Next 20 " + analy_type; 
							else {
								rowButton = "Next 20 customer";
								analy_type = "customer";
							}
							
							if ( prod_order == null) prod_order = "alpha";
						%>
						
						
				<% if (rowList.size() == 20 )	{ %>
						<form action = "salesAnalytics.jsp" method ="post"> 
							<input type = "hidden" name = "rowOffs" value = "<%= currRowOffset %>" />
							<input type = "hidden" name = "colOffs" value = "<%= currColOffset %>" />
							<input type = "hidden" name = "analysisType" value = "<%= analy_type %>" />
							<input type = "hidden" name = "orderBy" value = "<%= prod_order %>" />
							<input type = "hidden" name = "nextButton" value = "nextRow" />
							<input type = "submit" value = "<%= rowButton %>" />
						</form>
				<% } %>		
						
				<% if (prodList.size() == 10) { %>		
						<form atction = "salesAnalytics.jsp" method = "post">
							<input type = "hidden" name = "rowOffs" value = "<%= currRowOffset %>" />						
							<input type = "hidden" name = "colOffs" value = "<%= currColOffset %>" />
							<input type = "hidden" name = "analysisType" value = "<%= analy_type %>" />
							<input type = "hidden" name = "orderBy" value = "<%= prod_order %>" />
							<input type = "hidden" name = "nextButton" value = "nextCol" />							
							<input type = "submit" value = "Next 10 Products" />
						</form>
				<% } %>		
						
							
					</div>	
					</td>
					
					
				</tr>
				</table>

		
		
		
		
		<% 
			final long pageEndTime = System.currentTimeMillis();
			System.out.println("Running Time of SalesAnalytic Page: " + (pageEndTime - pageStrTime) + "ms");
			System.out.println(" ");
			stmt.close();
			conn.close();
			}
			catch(SQLException e){
				out.println("Cannot connect to db !");
			}
			finally{
					if (myRs != null) {
		                try {
		                    myRs.close();
		                } catch (SQLException e) { } // Ignore
		                myRs = null;
		            }
					if (conn != null) {
		                try {
		                    conn.close();
		                } catch (SQLException e) { } // Ignore
		                conn = null;
		            }
				}
		}
		
		
			else{%>
			
				<h3>This page is available to owners only</h3>
			<% } %>
	
	<% }
	
	else { %>
			<h3>Please <a href = "./login.jsp">login</a> before viewing the page</h3>
	<%} %>
</body>
</html>