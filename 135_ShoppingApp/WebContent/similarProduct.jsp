<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
    pageEncoding="ISO-8859-1"%>
<%@ page import = "java.sql.*" import = "java.until.*" import="java.util.List"
	import="java.util.ArrayList" import = "java.util.Formatter" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
<title>Similar Product Page</title>
</head>
<body>

	<%
	if(session.getAttribute("roleName") != null) { %>
		<table cellspacing="5">
			<tr>
				<td valign="top"><jsp:include page="./menu.jsp"></jsp:include></td>
				<td></td>
				<td>
					<h3>Hello <%= session.getAttribute("personName") %></h3>
					<h3>Similar Product Page</h3>
					
		
	<%			
		Connection conn = null;
		Statement stmt = null;
		ResultSet myRs = null;
		String sql = "select tt1.prod_id, tt1.product_name AS pd1, tt2.prod_id, tt2.product_name AS pd2, (sum(tt1.amount*tt2.amount)/(tt1.total * tt2.total)) as similarity  from "+
				 " (select t1.prod_id, t1.product_name, t1.ps_id, t1.amount, t4.total from "+ 
						" (select  p.id AS prod_id , p.product_name, ps.id as ps_id, COALESCE(sum(pc.price * pc.quantity),0) as amount from "+
						" product as p left join products_in_cart as pc on pc.product_id = p.id "+
						" left join (select person_id, id from shopping_cart where is_purchased = TRUE) as sc on sc.id = pc.cart_id "+
						" left join person as ps on ps.id = sc.person_id "+
						" group by p.id, p.product_name, ps.id "+
						" order by p.id) as t1 left join (select  p.id AS prod_id , p.product_name, sum(amount) as total "+
						" from product as p left join (select cart_id, product_id, COALESCE(sum(price *quantity),0) as amount from products_in_cart group by cart_id, product_id) as pc on pc.product_id = p.id "+
						" left join (select person_id, id from shopping_cart where is_purchased = TRUE) as sc on sc.id = pc.cart_id "+
						" left join person as ps on ps.id = sc.person_id "+
						" group by p.id, p.product_name "+
						" order by p.id) as t4 on t1.prod_id = t4.prod_id) as tt1, "+ 
						" (select t1.prod_id, t1.product_name, t1.ps_id, t1.amount, t4.total from "+ 
						" (select  p.id AS prod_id , p.product_name, ps.id as ps_id, COALESCE(sum(pc.price * pc.quantity),0) as amount from "+
						" product as p left join products_in_cart as pc on pc.product_id = p.id "+
						" left join (select person_id, id from shopping_cart where is_purchased = TRUE) as sc on sc.id = pc.cart_id "+
						" left join person as ps on ps.id = sc.person_id "+
						" group by p.id, p.product_name, ps.id "+
						" order by p.id) as t1 left join (select  p.id AS prod_id , p.product_name, sum(amount) as total "+
						" from product as p left join (select cart_id, product_id, COALESCE(sum(price *quantity),0) as amount from products_in_cart group by cart_id, product_id) as pc on pc.product_id = p.id "+
						" left join (select person_id, id from shopping_cart where is_purchased = TRUE) as sc on sc.id = pc.cart_id "+
						" left join person as ps on ps.id = sc.person_id "+
						" group by p.id, p.product_name "+
						" order by p.id) as t4 on t1.prod_id = t4.prod_id) as tt2 "+
						" where tt2.ps_id = tt1.ps_id AND tt1.prod_id < tt2.prod_id  "+
						" group by tt1.prod_id, tt1.product_name, tt2.prod_id, tt2.product_name, tt1.total, tt2.total "+
						" order by similarity DESC limit 100";
		try{
			

			Class.forName("org.postgresql.Driver");

			conn = DriverManager.getConnection("jdbc:postgresql://localhost/shoppingAppDB","postgres", "cse135");
			stmt = conn.createStatement();
			conn.setAutoCommit(false);
			
			final long prodQstrTime = System.currentTimeMillis();
			myRs = stmt.executeQuery(sql);
			final long prodQendTime = System.currentTimeMillis();
			System.out.println("Query Running Time: " + ( prodQendTime- prodQstrTime) + "ms");
			
			conn.commit();
        	conn.setAutoCommit(true); %>
        	<tr>
        	<table border = 1>
        	<tr>
        	<th>Product A</th>
        	<th>Product B</th>
        	<th>Similarity</th>
        	</tr>
        	<% while(myRs.next()){

        		%>
        	<tr>
        		<td><%= myRs.getString("pd1") %></td>
        		<td><%= myRs.getString("pd2") %></td>
        		<td><%= myRs.getDouble("similarity") %></td>
        	</tr>	
        	<% } %>
        	</table>
        	</tr>
        
        	
        <%
        	myRs.close();
			stmt.close();
			conn.close();
		}catch(SQLException e)
		{
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
	else{ %>
		<h3>Please <a href = "./login.jsp">login</a> before viewing the page</h3>
	<% } %>
</body>
</html>