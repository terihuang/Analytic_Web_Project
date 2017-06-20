<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1"%>
 <%@ page import = "java.sql.*" import = "java.until.*" import="java.util.List"
	import="java.util.ArrayList"  import = "org.json.JSONObject.*"%>
<%@page import="org.json.simple.JSONArray"%>
<%@page import="org.json.simple.JSONObject"%>
<%@page import="org.json.simple.parser.JSONParser"%>
<%@page import="org.json.simple.parser.ParseException"%>	
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>

<style> 
  .normal{background-color: white;} 
  .even{background-color: purple;} 
   .red{background-color: red;} 
   
  .element {
  	position: fixed;
  	top: 0;
  	right: 10;
  	background-color:green;
  	opacity: 0.8;
	}
</style>


<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
<title>State Top Sales Analytics</title>

<script type="text/javascript">

function showTable() 
{
	var xmlHttp;
	xmlHttp = new XMLHttpRequest();
  
	var url = "table.jsp";
	<% String str = request.getParameter("categ"); %>
	var s = "<%= str %>";
	url = url + "?cate=" + s;

	
  	var responseHandler = function() {
  		
  	    if( xmlHttp.readyState == 4 )	
  	    {
  	    	//parse the json object return from jsp
  	      	var result = JSON.parse(xmlHttp.responseText);
  	    
	        var arr = result.info;   
			var topProd = arr[0];
  	        var myObj = arr[1];			
			var diffProd = arr[2];
			var diffPrHe = arr[3];
			var diffStHe = arr[4];
			
			var newTopProd = "New Top 50 Product Not Showed In the Table: ";
			//var newTopProd = xmlHttp.responseText;
			var outProdIndex = [];
  	        var diff = Object.keys(diffProd);
  	        
  	    	var table = document.getElementById("saleTable"); 
  	    	var colHe = table.getElementsByTagName("th");
  	    	for( z = 1; z < colHe.length; z++){
  	    		colHe[z].className = "normal";
  	    	}
  	        
  	      	for(k in diff){
  	        	if(document.getElementById(diff[k])){
  	        		document.getElementById(diff[k]).className = "even";
  	        		var index = topProd[diff[k]];
  	        		outProdIndex.push(index);
  	        	}
  	        	
  	        	else{

  	        		newTopProd = newTopProd + "[" + diff[k] + "]  ";
  	        	}
  	        }
  	        
  	    	
  	        var rows = table.getElementsByTagName("tr");  
  	        
  	        for(i = 0; i < rows.length; i++){  
  	        	var cels = rows[i].getElementsByTagName("td");
  	        	for(j = 0 ; j < cels.length; j++ ){
  	        		cels[j].className = "normal";
  	        		for( l= 0; l < outProdIndex.length; l++){
  	        			if(outProdIndex[l] == j){
  	        				cels[j].className = "even";
  	        			}
  	        	 	}		
  	        	}
  	        }
  	        
  	    	var name = Object.keys(myObj);
  	    	
  	    	for(i in name){
  	    		
  	       		if(document.getElementById(name[i])){
  	       		 
  	       			document.getElementById(name[i]).className = "red";
  	       			var oldSale = parseInt(document.getElementById(name[i]).innerText);
  	       			document.getElementById(name[i]).innerHTML = oldSale + myObj[name[i]];        		
  	       	 	}
  	       	}
  	    	
  	    	
  	    	// change column hearder color to red if that product have new sales
  	    	var changePr = Object.keys(diffPrHe);
  	    	
  	    	for(x in changePr){
  	    		
  	       		if(document.getElementById(changePr[x])){
  	       			document.getElementById(changePr[x]).className = "red";       		
  	       	 	}
  	       	}
  	    	
  	    	// change row header color red if that state have new sales
  	    	var changeSt = Object.keys(diffStHe);
  	    	
  	    	for(y in changeSt){
  	    		
  	       		if(document.getElementById(changeSt[y])){
  	       			document.getElementById(changeSt[y]).className = "red";      		
  	       	 	}
  	       	}
  	    	
  	    	
  	    	document.getElementById("newInfo").innerHTML = newTopProd;     

  	    }
  	 }

  	  xmlHttp.onreadystatechange = responseHandler ;

  	  xmlHttp.open("GET", url, true);
  	  xmlHttp.send(null);

}

</script>

</head>

<body>

<p id = "newInfo"> </p>

<h3> Hello <%= session.getAttribute("personName") %> </h3>
<h3> State Top Sales Analytics Page </h3>


	<% 
	if(session.getAttribute("roleName") != null) { 
	String role = session.getAttribute("roleName").toString();
		
		if("owner".equalsIgnoreCase(role) == true){
			
			Connection conn = null;
			PreparedStatement pst = null;
			Statement stmt = null;
			ResultSet myRs = null;
			ResultSet pRs = null;
			ResultSet stRs = null;
			ResultSet tRs = null;
			ResultSet catRs = null;
			
			//check if specific category was selected
			String catego = request.getParameter("categ");
			
			String filterInfo;
			if(catego == null) {filterInfo = "All";}
			else {filterInfo = catego;}
			
			%>
			
			<p2 style="font-weight:bold"> Category Filter:[ <%= filterInfo %> ] </p2>
			
			<% 
			
			
		try{	
			Class.forName("org.postgresql.Driver");
			conn = DriverManager.getConnection("jdbc:postgresql://localhost/shoppingAppDB","postgres", "cse135");
		

			String prodQuery = "";
			String stQuery = "";
			String formQuery = "";
			String dTopProdQuery = "";
			String topProdQuery = "";
			String cateQuery = "";
			session.setAttribute("offset",0);
			String delQuery = "DELETE FROM logtable2";
			conn.setAutoCommit(false);			
			Statement dstmt2 = conn.createStatement();
			
			int rs2 = dstmt2.executeUpdate(delQuery);
			conn.commit();
			conn.setAutoCommit(true);
			String lu = "update last set lu = 0 ";
			Statement up = conn.createStatement();
			int rss = up.executeUpdate(lu);
			if ( catego == null || catego.equals("all") ) {
			
				prodQuery = "SELECT * from product_with_sale ORDER BY spend DESC LIMIT 50";
				
				stQuery = "SELECT * from state_with_sale ORDER BY total_sale DESC";
				
				formQuery = "select oa.state_id, oa.state_name, oa.product_id, oa.product_name, oa.cell_sum, oa.state_sum, oa.product_sum " + 
							"from over_all as oa INNER JOIN ( " +
							"select product_name, id, spend " +
							"from product_with_sale order by spend DESC LIMIT 50) as op "+
							"on op.id = oa.product_id ";
			}
			
			else {
				

				prodQuery = "SELECT * from product_with_sale WHERE category_name = '" + catego + "' ORDER BY spend DESC LIMIT 50";
				
				stQuery = "SELECT state_name, sum(cell_sum) as total_sale from over_all " +
						  "WHERE category_name = '"+ catego + "' GROUP BY state_name ORDER BY total_sale DESC";
				
				formQuery = "select oa.state_id, oa.state_name, oa.product_id, oa.product_name, oa.cell_sum, oa.state_sum, oa.product_sum " + 
							"from over_all as oa INNER JOIN ( " +
							"select product_name, id, spend " +
							"from product_with_sale WHERE category_name = '" + catego + "' order by spend DESC LIMIT 50) as op " +
							"on op.id = oa.product_id ";
			}
			
			cateQuery = "SELECT category_name FROM product_with_sale GROUP BY category_name ORDER BY category_name ";
		
			//get category show in a dropdown list
			conn.setAutoCommit(false);
			stmt = conn.createStatement();
			catRs = stmt.executeQuery(cateQuery);
			conn.commit();
			conn.setAutoCommit(true);
			
			%>
			
			<div class = element >
			<form name="myForm" action="nowhere" method="GET">

			<input type = "button" id="tableButton" value = "Refresh" onclick = "showTable()" />

			</form>
			
			
				
			<form method = post action="topKanalytics.jsp">
				
				<input type = "submit" value = "Run Query"/>
				<p>Category</p>
				<select name = "categ">
					<option value = "all">All</option>
					<% while (catRs.next()){%>
						<option value = "<%= catRs.getString("category_name")%>"><%= catRs.getString("category_name")%></option>
					<%}
					catRs.close();%>
				</select>
	
				
			</form>			
			</div>
			<% 
			
			catRs.close();
			
			//clean top product table
			dTopProdQuery = "DELETE FROM top_product";
			conn.setAutoCommit(false);
			stmt = conn.createStatement();
			int rs = stmt.executeUpdate(dTopProdQuery);
			conn.commit();
			conn.setAutoCommit(true);
			stmt.close();
			
			//update top product table with new products
			if ( catego == null || catego.equals("all") ) {
				topProdQuery = "INSERT INTO top_product ( SELECT product_name, spend FROM product_with_sale ORDER BY spend DESC LIMIT 50 )";
			}
			else{
				topProdQuery = "INSERT INTO top_product ( SELECT product_name, spend FROM product_with_sale " +
								"WHERE category_name = '" + catego + "' ORDER BY spend DESC LIMIT 50 )";
			}
			
			conn.setAutoCommit(false);
			stmt = conn.createStatement();
			int rs1 = stmt.executeUpdate(topProdQuery);
			conn.commit();
			conn.setAutoCommit(true);
			stmt.close();
			
			
			//store products by sales
			conn.setAutoCommit(false);
			stmt = conn.createStatement();
			pRs = stmt.executeQuery(prodQuery);
			conn.commit();
			conn.setAutoCommit(true);
			List<String> prodList = new ArrayList<String>();
			List<String> prodListSale = new ArrayList<String>();
			int prodCnt = 0;
			String prod, sale, prodWithSale = "";
			
			while (pRs.next()) {
				prod = pRs.getString("product_name");
				sale = " ($" + pRs.getString("spend") + ")";
				//prodWithSale = prod + " ($ " + sale + " )";
				prodList.add(prodCnt, prod);
				//prodListSale.add(prodCnt, prodWithSale);
				prodListSale.add(prodCnt, sale);
				prodCnt++;
			}
			
			pRs.close();
			

			
			// store states by sales
			conn.setAutoCommit(false);
			stmt = conn.createStatement();
			stRs = stmt.executeQuery(stQuery);
			conn.commit();
			conn.setAutoCommit(true);

			List<String> stList = new ArrayList<String>();
			List<String> stListSale = new ArrayList<String>();		
			String stName, stSale, stWithSale = "";			
			int stCnt = 0;

			
			while (stRs.next()) {
				stName = stRs.getString("state_name");
				stSale = "($" +  stRs.getString("total_sale") + ")";
				//stWithSale = stName + " ($ " + stSale + " )";
				stList.add(stCnt, stName);
				//stListSale.add(stCnt, stWithSale);
				stListSale.add(stCnt, stSale);
				stCnt++;
			}
			
			stRs.close();
			
			
			
			conn.setAutoCommit(false);
			stmt = conn.createStatement();
			myRs = stmt.executeQuery(formQuery);
			conn.commit();
			conn.setAutoCommit(true);			
			
			String currName, prevName = "";

			int[][] outTable = new int[56][50];
			int st_index = 0;
			int pr_index = 0;
			boolean start = false;
			
			while( myRs.next() ) {
				currName = myRs.getString("state_name");
				
				if(!start){
					prevName = currName;
					start = true;

				}
				

				pr_index = prodList.indexOf(myRs.getString("product_name"));
				st_index = stList.indexOf(myRs.getString("state_name"));
				
				outTable[st_index][pr_index] = myRs.getInt("cell_sum");

			}
			
			myRs.close();
			

			%>		
	

	
		<table border = 1 id = "saleTable">
		
			<th width  = "4%" > States </th>
			
			<% for(int i = 0; i < prodList.size(); i++ ) { %>
			<th id = "<%= prodList.get(i) %>"> <%= prodList.get(i) %> <br> <%= prodListSale.get(i) %> </th>
			<% } %>
		
			<% for( int i = 0; i < stList.size(); i++ ) { %>
			<tr> 
				<td id = "<%= stList.get(i) %>" widht = "4%" style="font-weight:bold"> <%= stList.get(i) %> <br> <%= stListSale.get(i) %> </td>
				
				<% for ( int j = 0; j < prodList.size(); j++ ) { 
						String st = stList.get(i);
						String pr = prodList.get(j);
						String cellId = st + pr;
				%>

						<td id = "<%= cellId %>" width = "5%"> <%=outTable[i][j] %> </td>
				<% } %> 
			
			</tr>
			<% } %>		 
		
		</table>
	 



		<% 
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